import UIKit

/// Main entry point for TyradsSDK. Use `Tyrads.instance`.
///
/// This is a thin presentation-layer facade. Session state lives in
/// `TyradsSessionStore`; business logic lives in the Domain use cases.
public final class Tyrads {
    public static let instance = Tyrads()
    private init() {
        // Wired up front, not inside initialize() — the host app owns push
        // permission and can call registerForRemoteNotifications() (and thus
        // trigger didRegisterForRemoteNotifications) at any time, including
        // before initialize() is ever called.
        apnsTokenNotifier.value = session.apnsToken
        TyradsAPNsManager.shared.onTokenUpdated = { [weak self] token in
            self?.apnsTokenNotifier.value = token
            self?.handleAPNsTokenUpdate(token)
        }
    }

    // MARK: - Dependencies

    private let session = TyradsSessionStore.shared

    private lazy var loginUseCase = TyradsLoginUserUseCase(
        authRepository: TyradsAuthRepositoryImpl(),
        deviceInfo: TyradsDeviceInfoProvider(),
        advertisingId: TyradsAdvertisingIdProvider(),
        session: session
    )
    private let trackUseCase = TyradsTrackActivityUseCase(
        repository: TyradsTrackingRepositoryImpl()
    )
    private let updatePushTokenUseCase = TyradsUpdatePushTokenUseCase(
        authRepository: TyradsAuthRepositoryImpl()
    )

    // MARK: - State

    public var apiKey: String?
    public var apiSecret: String?
    public var engagementId: String?
    public var placementId: String?
    public var config: TyradsConfig = TyradsConfig()
    public var mediaSourceInfo: TyradsMediaSourceInfo?
    public var userInfo: TyradsUserInfo?
    public var launchMode: TyradsLaunchMode?
    public var newUser: Bool = false

    /// Session state, proxied to `TyradsSessionStore` (single source of truth).
    public var publisherUserID: String {
        get { session.publisherUserID }
        set { session.publisherUserID = newValue }
    }
    public var token: String {
        get { session.token }
        set { session.token = newValue }
    }
    public var selectedLanguage: String {
        get { session.language }
        set { session.language = newValue }
    }
    var isSecure: Bool { session.isSecure }

    public var colorHeaderBg: UIColor?
    public var colorHeaderFg: UIColor?
    public var colorMain: UIColor?
    public var colorPremium: UIColor?
    public var colorPremiumFg: UIColor?

    public let deepLinkNotifier: TyradsValueNotifier<String?> = TyradsValueNotifier(nil)

    /// The current APNs device token, if one has been captured yet.
    public var apnsToken: String? { session.apnsToken }
    /// Fires with the latest APNs token every time a fresh one is captured
    /// (including a late arrival after login already completed).
    public let apnsTokenNotifier: TyradsValueNotifier<String?> = TyradsValueNotifier(nil)

    private var isInitCalled = false
    private var isLoginCalled = false

    private let continuationLock = NSLock()
    private var _isLoginSuccessful = false
    public var isLoginSuccessful: Bool {
        continuationLock.withLock { _isLoginSuccessful }
    }
    private var _initializationContinuations: [CheckedContinuation<Bool, Never>] = []
    private var _initializationCompleted = false

    private var callbacks: [TyradsCallbackType: TyradsCallback] = [:]
    private var webViewController: TyradsWebViewController?

    /// Error info from the last failed `loginUser()` call. Nil when login succeeds.
    public private(set) var lastLoginError: (title: String, message: String)?

    // MARK: - Init

    /// Call once from your AppDelegate or SceneDelegate before any other SDK method.
    public func initialize(
        apiKey: String,
        apiSecret: String,
        encryptionKey: String? = nil,
        engagementId: String? = nil,
        placementId: String? = nil,
        mediaSourceInfo: TyradsMediaSourceInfo? = nil,
        userInfo: TyradsUserInfo? = nil,
        config: TyradsConfig? = nil,
        launchMode: TyradsLaunchMode? = nil
    ) {
        precondition(!apiKey.isEmpty, "apiKey cannot be empty.")
        precondition(!apiSecret.isEmpty, "apiSecret cannot be empty.")

//        
//        let engagementIDInt: Int? = {
//          guard let engagementId = self.engagementId, !engagementId.isEmpty else { return nil }
//          return Int(engagementId)
//        }()
//
//        let placementIDInt: Int? = {
//          guard let placementId = self.placementId, !placementId.isEmpty else { return nil }
//          return Int(placementId)
//        }()
//        
        isInitCalled = true
        continuationLock.withLock {
            _initializationCompleted = false
            _isLoginSuccessful = false
        }
        self.apiKey = apiKey
        self.apiSecret = apiSecret
        self.engagementId = engagementId
        self.placementId = placementId
        self.mediaSourceInfo = mediaSourceInfo
        self.userInfo = userInfo
        self.launchMode = launchMode
        self.config = config ?? TyradsConfig()

        session.persistCredentials(apiKey: apiKey, apiSecret: apiSecret)
        if let key = encryptionKey {
            session.enableEncryption(key: key)
        }

        TyradsLocalizationService.shared.initialize(languageCode: session.language)

        print("[TyradsSDK] Initialized. Language: \(session.language)")
    }

    /// A fresh APNs token can arrive after `loginUser()` already captured the
    /// token for its payload (e.g. the user takes a while to respond to the
    /// permission prompt on first install, or the token lands mid-login).
    /// When that happens, resend it here instead of leaving the backend with
    /// a stale/missing token until the next login.
    private func handleAPNsTokenUpdate(_ token: String) {
        guard isLoginSuccessful, token != session.lastSentApnsToken else { return }
        Task {
            do {
                try await updatePushTokenUseCase(token: token)
                session.lastSentApnsToken = token
                print("[TyradsSDK] Push token updated after login: \(token)")
            } catch {
                print("[TyradsSDK] Failed to update push token: \(error)")
            }
        }
    }

    // MARK: - Login

    /// Authenticate the user with the Tyrads backend. Call after `initialize`.
    @discardableResult
    public func loginUser(userID: String? = nil) async -> Bool {
        precondition(isInitCalled, "initialize() must be called before loginUser().")
        isLoginCalled = true

        var resolvedUserID = userID ?? ""
        if resolvedUserID.isEmpty {
            resolvedUserID = session.storedUserId ?? ""
        }

        // Whatever token is already captured at this instant — the SDK
        // doesn't request push permission itself, so it never waits on one.
        let apnsTokenAtLogin = session.apnsToken

        let params = TyradsLoginParams(
            userID: resolvedUserID,
            engagementId: engagementId,
            placementId: placementId,
            mediaSourceInfo: mediaSourceInfo,
            userInfo: userInfo,
            apnsToken: apnsTokenAtLogin
        )

        do {
            let result = try await loginUseCase(params)

            session.publisherUserID = result.publisherUserId
            session.token = result.token
            // Record what the login payload actually carried — not the current
            // token, which may have changed while the request was in flight.
            session.lastSentApnsToken = apnsTokenAtLogin

            // Apply UI-facing state on the main actor: these properties are read
            // by SwiftUI/UIKit on the main thread, so writing them off-main races
            // on their reference counts.
            await MainActor.run {
                newUser = result.newRegisteredUser
                colorMain = UIColor(hex: result.mainColorHex)
                colorHeaderBg = UIColor(hex: result.headerColorHex)
                colorHeaderFg = colorHeaderBg?.fontColorForBackground()
                colorPremium = UIColor(hex: result.premiumColorHex) ?? TyradsSDKConfig.secondaryColor
                colorPremiumFg = colorPremium?.fontColorForBackground()
            }

            lastLoginError = nil
            track(TyradsActivity.initialized)
            print("[TyradsSDK] Login successful. token=\(session.token.prefix(20))...")

            // Delay InAppNotification fetch by 2s so it doesn't race with
            // WKWebView's XPC networking process startup on iOS 26.
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await TyradsInAppNotificationViewModel.shared.initialize()
                await MainActor.run {
                    TyradsInAppNotificationManager.shared.evaluatePromotions()
                }
            }
            resumeWaiters(result: true)
            // A token that arrived mid-login was dropped by handleAPNsTokenUpdate
            // (login not yet successful) — resend it now.
            if let current = session.apnsToken, current != apnsTokenAtLogin {
                handleAPNsTokenUpdate(current)
            }
            return isLoginSuccessful
        } catch {
            print("[TyradsSDK] Login error: \(error)")
            if case NetworkError.httpError(let code, let data) = error {
                let info = NetworkError.apiErrorInfo(from: data, statusCode: code)
                lastLoginError = (title: info.title, message: info.message)
            } else {
                lastLoginError = (title: "Login Failed", message: error.localizedDescription)
            }
            resumeWaiters(result: false)
            return false
        }
    }

    // MARK: - Logout

    public func logoutUser() {
        precondition(isInitCalled, "initialize() must be called before logoutUser().")
        session.clear()
        continuationLock.withLock {
            _isLoginSuccessful = false
            _initializationCompleted = false
        }
    }

    // MARK: - Show Offers

    /// Present the offerwall. Call after `loginUser` succeeds.
    public func showOffers(
        campaignID: Int? = nil,
        route: String? = nil,
        launchMode: TyradsLaunchMode? = nil,
        from viewController: UIViewController? = nil
    ) async throws {
        precondition(isInitCalled, "initialize() must be called before showOffers().")
        precondition(isLoginCalled, "loginUser() must be called before showOffers().")

        let loginOK = await waitAndCheck()
        print("[TyradsSDK] showOffers: loginOK=\(loginOK)")
        guard loginOK else { return }

        let targetRoute = route ?? TyradsDeepRoutes.offers
        let webURL = getWebURL(campaignID: campaignID, route: targetRoute)

        // Onboarding (privacy) gate runs before launch mode is resolved, so the
        // external browser path is also gated — matching the Flutter SDK.
        let ready = await checkOnboardingStatus(from: viewController)
        guard ready else { return }

        let effectiveLaunchMode = launchMode ?? self.launchMode ?? .webview

        if effectiveLaunchMode == .externalBrowser {
            await UIApplication.shared.open(webURL)
            track(TyradsActivity.opened)
            return
        }

        await MainActor.run {
            let webVC = TyradsWebViewController(url: webURL)
            webViewController = webVC
            let nav = UINavigationController(rootViewController: webVC)
            nav.modalPresentationStyle = .fullScreen
            let presenter = viewController ?? topViewController()
            presenter?.present(nav, animated: true)
        }
        track(TyradsActivity.opened)
    }

    // MARK: - Language

    public func changeLanguage(_ languageCode: String) {
        precondition(isInitCalled, "initialize() must be called before changeLanguage().")
        session.language = languageCode
        TyradsLocalizationService.shared.changeLanguage(languageCode)
        Task { @MainActor in
            TyradsPremiumWidgetsViewModel.shared.refresh(force: true)
        }
    }

    // MARK: - Callbacks

    public func setCallback(_ type: TyradsCallbackType, callback: @escaping TyradsCallback) {
        callbacks[type] = callback
    }

    public func triggerCallback(_ type: TyradsCallbackType, _ data: [String: Any]) {
        callbacks[type]?(data)
    }

    // MARK: - Tracking

    public func track(_ activity: String) {
        Task {
            do {
                try await trackUseCase(activity)
            } catch {
                print("[TyradsSDK] Tracking error: \(error)")
            }
        }
    }

    // MARK: - Config

    /// Returns the top offers widget. Equivalent to Flutter's `Tyrads.instance.topOffersWidget(context)`.
    public func topOffersWidget(widgetStyle: TyradsPremiumWidgetStyle = .list) -> TyradsPremiumOffersView {
        TyradsPremiumOffersView(widgetStyle: widgetStyle)
    }

    public func setLaunchMode(_ mode: TyradsLaunchMode) {
        launchMode = mode
    }

    public func setTyradsConfig(_ config: TyradsConfig) {
        self.config = config
    }

    // MARK: - URL Builder

    public func getWebURL(campaignID: Int? = nil, route: String? = nil) -> URL {
        let currentRoute = route ?? TyradsDeepRoutes.offers
        var components = URLComponents()
        components.scheme = "https"
        components.host = "v4.sdk.tyrads.com"
        var params: [URLQueryItem] = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "to", value: campaignID.map { "\(currentRoute)/\($0)" } ?? currentRoute),
            URLQueryItem(name: "lang", value: selectedLanguage),
        ]
        if let pid = placementId { params.append(URLQueryItem(name: "placementId", value: String(pid))) }
        components.queryItems = params
        return components.url!
    }

    // MARK: - Internal helpers

    public func waitAndCheck() async -> Bool {
        let alreadyDone: Bool = continuationLock.withLock { _initializationCompleted }
        if alreadyDone { return isLoginSuccessful }
        return await withCheckedContinuation { continuation in
            continuationLock.withLock { _initializationContinuations.append(continuation) }
        }
    }

    private func resumeWaiters(result: Bool) {
        let waiters: [CheckedContinuation<Bool, Never>] = continuationLock.withLock {
            _isLoginSuccessful = result
            _initializationCompleted = true
            let w = _initializationContinuations
            _initializationContinuations.removeAll()
            return w
        }
        waiters.forEach { $0.resume(returning: result) }
    }

    /// Runs the pre-offer onboarding gate (privacy policy when required).
    /// Mirrors Flutter's `OnboardingCheck.checkOnboardingStatus` (iOS scope:
    /// usage-permission steps are Android-only). Returns false if the user is
    /// not logged in or declines the privacy policy.
    @discardableResult
    public func checkOnboardingStatus(from viewController: UIViewController? = nil) async -> Bool {
        guard await waitAndCheck() else { return false }
        if !config.skipInitialPages && !session.isPrivacyAccepted(forUserId: publisherUserID) {
            let accepted = await showPrivacyPolicy(from: viewController)
            guard accepted else { return false }
            guard session.isPrivacyAccepted(forUserId: publisherUserID) else { return false }
        }
        return true
    }

    private func showPrivacyPolicy(from viewController: UIViewController?) async -> Bool {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                let privacyVC = TyradsPrivacyPolicyViewController()
                privacyVC.onAccepted = { continuation.resume(returning: true) }
                privacyVC.onDeclined = { continuation.resume(returning: false) }

                let nav = UINavigationController(rootViewController: privacyVC)
                nav.modalPresentationStyle = .formSheet
                let presenter = viewController ?? self.topViewController()
                presenter?.present(nav, animated: true)
            }
        }
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return findTop(root)
    }

    private func findTop(_ vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController { return findTop(presented) }
        if let nav = vc as? UINavigationController { return findTop(nav.visibleViewController ?? nav) }
        if let tab = vc as? UITabBarController { return findTop(tab.selectedViewController ?? tab) }
        return vc
    }
}

// MARK: - ValueNotifier (lightweight equivalent of Flutter's ValueNotifier)

public final class TyradsValueNotifier<T> {
    public var value: T {
        didSet { observers.forEach { $0(value) } }
    }
    private var observers: [(T) -> Void] = []

    public init(_ initialValue: T) {
        value = initialValue
    }

    public func addObserver(_ observer: @escaping (T) -> Void) {
        observers.append(observer)
    }
}
