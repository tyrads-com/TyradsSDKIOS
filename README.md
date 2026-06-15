# TyradsSDK iOS

Offerwall and in-app monetization SDK for iOS.

## Requirements

- iOS 15+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**, enter your repository URL.

Or add directly to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/TyradsSDKIOS.git", from: "4.0.0")
]
```

Then add `TyradsSDKIOS` to your target's dependencies.

---

## Quick Start

### 1. Initialize

Call `initialize` once — in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` or `SceneDelegate.scene(_:willConnectTo:)`.

```swift
import TyradsSDKIOS

Tyrads.instance.initialize(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET"
)
```

### 2. Login

Call `loginUser` after `initialize`. Awaitable — resolves when the backend responds.

```swift
Task {
    let success = await Tyrads.instance.loginUser(userID: "user_123")
}
```

`userID` is optional. If omitted, the SDK reuses the last stored user ID.

### 3. Show Offerwall

```swift
try? await Tyrads.instance.showOffers()
```

Presents the offerwall in a full-screen modal WebView.

---

## Initialize Options

All parameters except `apiKey` and `apiSecret` are optional.

```swift
Tyrads.instance.initialize(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET",
    encryptionKey: "YOUR_32_BYTE_ENC_KEY",   // enables secure mode
    engagementId: "123",                       // integer string
    placementId: "456",                        // integer string
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
        sub1: "ReferralCode123",   // custom, not sent on postback
        sub2: "OrganicInstall",    // custom, not sent on postback
        sub3: "HighValueUser",     // custom, sent on postback
        sub4: "FirstTimeUser",     // custom, sent on postback
        sub5: "iOSDevice"          // custom, not sent on postback
    ),
    userInfo: TyradsUserInfo(
        email: "user@example.com",
        phoneNumber: "001234567890",  // replace + with 00
        userGroup: "High purchase user",
        age: 28,
        gender: 1  // 1 = male, 2 = female
    ),
    config: TyradsConfig(skipInitialPages: false),  // set true to skip privacy gate
    launchMode: .webview
)
```

---

## Show Offers Options

```swift
try? await Tyrads.instance.showOffers(
    campaignID: 42,                    // open directly to a specific campaign
    route: TyradsDeepRoutes.offers,    // deep route (see below)
    launchMode: .webview,              // override default launch mode
    from: self                         // presenter UIViewController; auto-detected if nil
)
```

### Deep Routes

| Constant | Route | Description |
|---|---|---|
| `TyradsDeepRoutes.offers` | `"offers"` | Main offerwall (default) |
| `TyradsDeepRoutes.activeOffers` | `"active-offers"` | User's active/installed offers |
| `TyradsDeepRoutes.support` | `"support"` | Support page |
| `TyradsDeepRoutes.settings` | `"settings"` | Settings page |

### Launch Modes

| Mode | Behavior |
|---|---|
| `.webview` | Opens in full-screen in-app WebView (default) |
| `.externalBrowser` | Opens in Safari |

Set a default in `initialize`:
```swift
Tyrads.instance.initialize(apiKey: "...", apiSecret: "...", launchMode: .externalBrowser)
```

Or override per call:
```swift
try? await Tyrads.instance.showOffers(launchMode: .externalBrowser)
```

---

## Premium Widgets

Embed a pre-built offers widget in any SwiftUI view. Shows the top 5 offers with premium campaigns first.

```swift
import TyradsSDKIOS
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            // other content
            Tyrads.instance.topOffersWidget(widgetStyle: .sliderCards)
                .frame(minHeight: 160)
        }
    }
}
```

The widget loads automatically after login and stays in sync with the SDK session.

### Widget Styles

```swift
public enum TyradsPremiumWidgetStyle {
    case list           // vertical list of offer cards
    case sliderCards    // horizontal scrolling card slider
    case sliderList     // horizontal scrolling compact list
}
```

Pass the style to `topOffersWidget`:

```swift
Tyrads.instance.topOffersWidget(widgetStyle: .list)
Tyrads.instance.topOffersWidget(widgetStyle: .sliderCards)
Tyrads.instance.topOffersWidget(widgetStyle: .sliderList)
```

---

## Callbacks

React to campaign events:

```swift
Tyrads.instance.setCallback(.campaignDetail) { data in
    print("Campaign detail viewed:", data)
}

Tyrads.instance.setCallback(.campaignActivated) { data in
    print("Campaign activated:", data)
}

Tyrads.instance.setCallback(.campaignInstalled) { data in
    print("Campaign installed:", data)
}
```

`data` is `[String: Any]` with campaign info.

---

## Language

Change the SDK display language at runtime:

```swift
Tyrads.instance.changeLanguage("id")   // Indonesian
Tyrads.instance.changeLanguage("en")   // English
```

This also refreshes the premium widget content.

---

## Deep Link Handling

The SDK exposes a `ValueNotifier` that fires when a push notification contains a deep link:

```swift
Tyrads.instance.deepLinkNotifier.addObserver { deepLink in
    guard let deepLink else { return }
    // navigate to deepLink
}
```

---

## Push Notifications (APNs)

Forward APNs lifecycle events from your `AppDelegate`:

```swift
import TyradsSDKIOS

class AppDelegate: NSObject, UIApplicationDelegate {

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

The SDK requests notification permission automatically during `initialize`. Deep links from notifications are delivered via `Tyrads.instance.deepLinkNotifier`.

---

## Waiting for Login

If you need to gate custom logic on login completion:

```swift
let loggedIn = await Tyrads.instance.waitAndCheck()
if loggedIn {
    // safe to access session, show UI, etc.
}
```

Returns immediately if login already completed; otherwise suspends until it does.

---

## Onboarding / Privacy Gate

The SDK shows a privacy policy screen before the offerwall on first launch (unless `skipInitialPages: true` is set in `TyradsConfig`). You can trigger this check manually:

```swift
let ready = await Tyrads.instance.checkOnboardingStatus()
guard ready else { return }
// user accepted privacy policy
```

---

## Logout

```swift
Tyrads.instance.logoutUser()
```

Clears stored session and resets login state. Call `loginUser` again to re-authenticate.

---

## Manual Tracking

Track custom activity events:

```swift
Tyrads.instance.track(TyradsActivity.opened)
Tyrads.instance.track(TyradsActivity.closed)
Tyrads.instance.track(TyradsActivity.profileUpdated)
```

Available activities: `initialized`, `profileUpdated`, `opened`, `targetedCampaignShown`, `targetedCampaignDetailShown`, `campaignActivated`, `supportTicketShown`, `closed`, `campaignActivatedRetry`.

The SDK tracks core events (open, close, campaign actions) automatically. Use manual tracking for custom integration points.

---

## Full Example (SwiftUI)

```swift
import SwiftUI
import TyradsSDKIOS

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    Tyrads.instance.initialize(
                        apiKey: "YOUR_API_KEY",
                        apiSecret: "YOUR_API_SECRET",
                        encryptionKey: "YOUR_ENC_KEY",
                        userInfo: TyradsUserInfo(email: "user@example.com"),
                        config: TyradsConfig(skipInitialPages: false)
                    )
                    await Tyrads.instance.loginUser(userID: "user_123")
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Tyrads.instance.topOffersWidget(widgetStyle: .sliderCards)
                .frame(minHeight: 160)

            Button("Open Offerwall") {
                Task { try? await Tyrads.instance.showOffers() }
            }
        }
    }
}
```

---

## UIKit Example

```swift
import UIKit
import TyradsSDKIOS

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Tyrads.instance.initialize(
            apiKey: "YOUR_API_KEY",
            apiSecret: "YOUR_API_SECRET"
        )
        Task { await Tyrads.instance.loginUser(userID: "user_123") }
        return true
    }
}

class OfferwallViewController: UIViewController {
    @IBAction func openOfferwall() {
        Task {
            try? await Tyrads.instance.showOffers(from: self)
        }
    }
}
```

---

## Notes

- `initialize` must be called before any other SDK method.
- `loginUser` must be called before `showOffers`.
- All async SDK methods are safe to call from `Task {}` blocks on any actor.
- The premium widget handles its own load/refresh lifecycle — no manual reload needed.
