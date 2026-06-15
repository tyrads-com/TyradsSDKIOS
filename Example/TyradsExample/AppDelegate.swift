import UIKit
import SwiftUI
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
