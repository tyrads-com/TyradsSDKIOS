# Push Notifications

Tyrads delivers push notifications to your app directly through Apple Push Notification service (APNs), using your app's own APNs credentials. No Firebase setup is required on iOS.

#### Prerequisites

**1. Enable capabilities in Xcode**

In your app target's **Signing & Capabilities** tab, add:

* **Push Notifications**
* **Background Modes** → check **Remote notifications**

**2. Provide your APNs credentials to Tyrads**

APNs device tokens are bound to your app's bundle ID and Apple Developer team, so Tyrads can only deliver notifications using an APNs key issued for your account. Create an APNs Authentication Key in the [Apple Developer portal](https://developer.apple.com/account/resources/authkeys/list) (**Certificates, Identifiers & Profiles → Keys**, with **Apple Push Notifications service (APNs)** enabled), then provide the following to Tyrads for your app:

| Credential | Where to find it |
| ---------- | ---------------- |
| APNs Auth Key (`.p8` file) | Downloaded once when creating the key. |
| Key ID | Shown next to the key in the Apple Developer portal. |
| Team ID | **Membership details** in the Apple Developer portal. |
| Bundle ID | Your app target's bundle identifier. |

{% hint style="warning" %}
Without these credentials, the SDK still captures and sends the device token, but notifications will not be delivered to your users.
{% endhint %}

#### Setup

{% hint style="warning" %}
The SDK never requests push permission itself — your app owns that decision, same as it would for any of its own push notification needs.
{% endhint %}

Request authorization and register for remote notifications yourself, then forward the lifecycle events to the SDK from your `AppDelegate`.

```swift
import UserNotifications
import TyradsSDKIOS

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
```

**Notification taps**

Tapping a displayed notification is delivered through `UNUserNotificationCenterDelegate`, not `didReceiveRemoteNotification`. Forward it too, so deep links open on tap:

```swift
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        TyradsAPNsManager.shared.didReceiveNotificationResponse(response)
        completionHandler()
    }
}
```

Set the delegate in `application(_:didFinishLaunchingWithOptions:)`, before it returns:

```swift
UNUserNotificationCenter.current().delegate = self
```

If your app already has a `UNUserNotificationCenterDelegate`, call `didReceiveNotificationResponse(_:)` from it instead — the SDK ignores notifications without a Tyrads deep link.

**SwiftUI apps**

iOS only delivers the APNs device token through `UIApplicationDelegate`, so SwiftUI apps need an `AppDelegate` too. Use the `AppDelegate` above and attach it to your `App` with `@UIApplicationDelegateAdaptor`:

```swift
import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

{% hint style="info" %}
If permission is requested after `initialize()` and the APNs token arrives late (e.g. the user takes a while to respond to the permission prompt), the SDK automatically resends the token once login has completed — no extra handling needed on your end.
{% endhint %}

#### Deep Links from Notifications

Deep links delivered via a push notification's payload are surfaced through a `ValueNotifier`:

```swift
Tyrads.instance.deepLinkNotifier.addObserver { deepLink in
    guard let deepLink else { return }
    // navigate to deepLink
}
```
