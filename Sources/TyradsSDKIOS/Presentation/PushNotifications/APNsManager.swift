import UIKit
import UserNotifications

public final class TyradsAPNsManager: NSObject {
    public static let shared = TyradsAPNsManager()
    private override init() { super.init() }

    /// Call from AppDelegate application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    public func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: TyradsKeyNames.apnsToken)
        print("[TyradsSDK] APNs token: \(token)")
    }

    /// Call from AppDelegate application(_:didFailToRegisterForRemoteNotificationsWithError:)
    public func didFailToRegisterForRemoteNotifications(error: Error) {
        print("[TyradsSDK] APNs registration failed: \(error)")
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[TyradsSDK] Push permission error: \(error)") }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
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
