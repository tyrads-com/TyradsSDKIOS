import UIKit
import SwiftUI
import UserNotifications
import TyradsSDKIOS

@main
struct TyradsExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // iOS 15: NavigationView uses transparent scrollEdgeAppearance by default,
        // causing content to be laid out from y=0 (behind nav bar) on the first
        // render pass, then corrected on the second — visible as a layout jump.
        // Force opaque appearance so the content area is always offset correctly.
        UIScrollView.appearance().delaysContentTouches = false

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    // The SDK never requests push permission itself — this app owns that,
    // same as it would for any of its own push notification needs. We ask
    // right at launch so the token is ready well before the user reaches a
    // screen that logs in.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error { print("[Example] Push permission error: \(error)") }
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        TyradsAPNsManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        TyradsAPNsManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        TyradsAPNsManager.shared.didReceiveRemoteNotification(
            userInfo: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Notification taps don't go through didReceiveRemoteNotification —
    // forward them so the SDK can surface the deep link.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        TyradsAPNsManager.shared.didReceiveNotificationResponse(response)
        completionHandler()
    }

    // Show banners while the app is in the foreground too.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
