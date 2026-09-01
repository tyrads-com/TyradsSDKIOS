import UIKit
import UserNotifications

public final class TyradsAPNsManager: NSObject {
    public static let shared = TyradsAPNsManager()
    private override init() { super.init() }

    private let lock = NSLock()
    private var tokenContinuations: [UUID: CheckedContinuation<String?, Never>] = [:]
    /// True from the moment `registerForRemoteNotifications()` is called until a token or
    /// failure arrives. `waitForToken` only blocks while this is true — if the user denied
    /// the permission prompt (or we're on a simulator that never registers), there's nothing
    /// to wait for, so callers get `nil` back immediately instead of eating a timeout.
    private var isRegistrationPending = false

    /// Call from AppDelegate application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    public func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: TyradsKeyNames.apnsToken)
        print("[TyradsSDK] APNs token: \(token)")
        resolveWaiters(with: token)
    }

    /// Call from AppDelegate application(_:didFailToRegisterForRemoteNotificationsWithError:)
    public func didFailToRegisterForRemoteNotifications(error: Error) {
        print("[TyradsSDK] APNs registration failed: \(error)")
        resolveWaiters(with: nil)
    }

    private func resolveWaiters(with token: String?) {
        lock.lock()
        isRegistrationPending = false
        let waiters = tokenContinuations
        tokenContinuations.removeAll()
        lock.unlock()
        waiters.values.forEach { $0.resume(returning: token) }
    }

    /// Returns the APNs token if already stored, otherwise waits (up to `timeout` seconds) for
    /// registration to complete — but only if a registration is actually in flight. Used by the
    /// login flow so a token that arrives a beat after `initialize()` still makes it into the
    /// login payload, without stalling every login when push permission was never granted.
    func waitForToken(timeout: TimeInterval = 3) async -> String? {
        if let stored = UserDefaults.standard.string(forKey: TyradsKeyNames.apnsToken) {
            return stored
        }

        lock.lock()
        let shouldWait = isRegistrationPending
        lock.unlock()
        guard shouldWait else { return nil }

        return await withCheckedContinuation { continuation in
            let id = UUID()
            lock.lock()
            tokenContinuations[id] = continuation
            lock.unlock()

            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
                guard let self else { return }
                self.lock.lock()
                let pending = self.tokenContinuations.removeValue(forKey: id)
                self.lock.unlock()
                pending?.resume(returning: nil)
            }
        }
    }

    /// Call from AppDelegate application(_:didReceiveRemoteNotification:fetchCompletionHandler:)
    public func didReceiveRemoteNotification(
        userInfo: [AnyHashable: Any],
        fetchCompletionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        handleNotification(userInfo: userInfo)
        fetchCompletionHandler(.newData)
    }

    func initialize() {
        requestPermission()
    }

    private func requestPermission() {
        // Set before the (async) authorization call resolves, so a `waitForToken` that
        // lands in the window between requesting and the completion handler firing still
        // knows to wait instead of bailing out early.
        lock.lock()
        isRegistrationPending = true
        lock.unlock()

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error { print("[TyradsSDK] Push permission error: \(error)") }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self?.resolveWaiters(with: nil)
            }
        }
    }

    private func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let data = userInfo["data"] as? [String: Any],
              let deepLink = data["deepLink"] as? String,
              !deepLink.isEmpty else { return }
        DispatchQueue.main.async {
            Tyrads.instance.deepLinkNotifier.value = deepLink
        }
    }
}
