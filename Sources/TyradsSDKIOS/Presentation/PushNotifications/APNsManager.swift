import UIKit
import UserNotifications

/// Pure receiver for APNs — this SDK never requests push permission or calls
/// `registerForRemoteNotifications()` itself. The host app owns that (it may
/// already have its own push flow for other purposes), and just forwards the
/// AppDelegate callbacks below.
public final class TyradsAPNsManager: NSObject {
    public static let shared = TyradsAPNsManager()
    private override init() { super.init() }

    /// Fired every time a fresh token is captured, including a late arrival
    /// after login already completed — lets callers resend a token that
    /// missed the original login payload.
    var onTokenUpdated: ((String) -> Void)?

    /// Call from AppDelegate application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
    public func didRegisterForRemoteNotifications(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: TyradsKeyNames.apnsToken)
        print("[TyradsSDK] APNs token: \(token)")
        onTokenUpdated?(token)
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

    /// Call from UNUserNotificationCenterDelegate
    /// userNotificationCenter(_:didReceive:withCompletionHandler:) — fires when
    /// the user taps a displayed notification, which does not go through
    /// didReceiveRemoteNotification.
    public func didReceiveNotificationResponse(_ response: UNNotificationResponse) {
        handleNotification(userInfo: response.notification.request.content.userInfo)
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
