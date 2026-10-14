import SwiftUI
import TyradsSDKIOS

// MARK: - ContentViewModel (MVVM)
// Owns all config/init/login state and actions. The View stays declarative.

@MainActor
final class ContentViewModel: ObservableObject {

    @Published var apiKey = ""
    @Published var apiSecret = ""
    @Published var encKey = ""
    @Published var engagementId = ""
    @Published var placementId = ""
    @Published var userId = ""
    /// Free text sent as-is — plain string or JSON (e.g. {"tier":"vip"}).
    @Published var userGroup = ""
    @Published var selectedAge: Int?
    @Published var selectedGender: Int?
    @Published var isLoading = false
    @Published var isInitialized = false
    @Published var widgetIsSlider: Bool = true
    @Published var errorTitle: String?
    @Published var errorMessage: String?
    @Published var apnsToken: String?
    var widgetStyle: TyradsPremiumWidgetStyle { widgetIsSlider ? .sliderCards : .list }

    private let prefs = UserDefaults.standard
    private var didLoad = false
    private var didObserveApnsToken = false

    var genderLabel: String {
        switch selectedGender {
        case 1: return "Male"
        case 2: return "Female"
        default: return "Gender: Any"
        }
    }

    // MARK: Actions

    func loadStoredAndInit() {
        observeApnsTokenIfNeeded()
        guard !didLoad else { return }
        didLoad = true
        apiKey = prefs.string(forKey: "apiKey") ?? ""
        apiSecret = prefs.string(forKey: "apiSecret") ?? ""
        encKey = prefs.string(forKey: "encKey") ?? ""
        userGroup = prefs.string(forKey: "userGroup") ?? ""
    }

    private func observeApnsTokenIfNeeded() {
        guard !didObserveApnsToken else { return }
        didObserveApnsToken = true
        apnsToken = Tyrads.instance.apnsToken
        Tyrads.instance.apnsTokenNotifier.addObserver { [weak self] token in
            Task { @MainActor in self?.apnsToken = token }
        }
    }

    func initializeIfNeeded() {
        guard !isInitialized else { return }
        initializeTyrads()
    }

    func initializeTyrads() {
        let finalKey    = apiKey
        let finalSecret = apiSecret
        let finalEncKey = encKey
        let finalUserId = nonEmpty(userId) ?? prefs.string(forKey: "tyrads_user_id") ?? "aatest_01"

        prefs.set(apiKey, forKey: "apiKey")
        prefs.set(apiSecret, forKey: "apiSecret")
        prefs.set(encKey, forKey: "encKey")
        prefs.set(userGroup, forKey: "userGroup")

        Tyrads.instance.initialize(
            apiKey: finalKey,
            apiSecret: finalSecret,
            encryptionKey: finalEncKey.isEmpty ? nil : finalEncKey,
            engagementId: nonEmpty(engagementId),
            placementId: nonEmpty(placementId),
            mediaSourceInfo: TyradsMediaSourceInfo(
                mediaSourceName: "Facebook",
                mediaCampaignName: "Summer2023Promo",
                mediaSourceId: "FB001",
                mediaSubSourceId: "FB001_Stories",
                incentivized: false,
                mediaAdsetName: "YoungAdults25-34",
                mediaAdsetId: "AD001",
                mediaCreativeName: "SummerSale_Video",
                mediaCreativeId: "CR001",
                sub1: "ReferralCode123",
                sub2: "OrganicInstall",
                sub3: "HighValueUser",
                sub4: "FirstTimeUser",
                sub5: "iOSDevice"
            ),
            userInfo: TyradsUserInfo(
                email: "example@tyrads.com",
                phoneNumber: "001234567890",
                userGroup: nonEmpty(normalizedUserGroup),
                age: selectedAge,
                gender: selectedGender
            ),
            config: TyradsConfig(skipInitialPages: true)
        )

        Task {
            await Tyrads.instance.loginUser(userID: finalUserId)
            prefs.set(finalUserId, forKey: "tyrads_user_id")
            Tyrads.instance.setCallback(.campaignDetail) { data in print("[Example] campaignDetail: \(data)") }
            Tyrads.instance.setCallback(.campaignActivated) { data in print("[Example] campaignActivated: \(data)") }
        }

        isInitialized = true
    }

    func showOfferwall() {
        guard !isLoading else { return }
        isLoading = true
        errorTitle = nil
        errorMessage = nil
        initializeTyrads()
        Task {
            let ok = await Tyrads.instance.waitAndCheck()
            isLoading = false
            guard ok else {
                let err = Tyrads.instance.lastLoginError
                errorTitle = err?.title ?? "Login Failed"
                errorMessage = err?.message ?? ""
                return
            }
            try? await Tyrads.instance.showOffers()
        }
    }

    /// iOS smart punctuation turns typed quotes into “ ” / ‘ ’, which breaks
    /// JSON — swap them back to straight quotes before sending.
    private var normalizedUserGroup: String {
        userGroup
            .replacingOccurrences(of: "[\u{201C}\u{201D}\u{201E}]", with: "\"", options: .regularExpression)
            .replacingOccurrences(of: "[\u{2018}\u{2019}]", with: "'", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// nil when empty, true/false for whether the input parses as JSON.
    var userGroupIsJSON: Bool? {
        let text = normalizedUserGroup
        guard !text.isEmpty, let data = text.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) != nil
            && (text.hasPrefix("{") || text.hasPrefix("["))
    }

    private func nonEmpty(_ s: String) -> String? {
        s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s
    }
}
