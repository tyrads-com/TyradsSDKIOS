# Initialization

{% hint style="warning" %}

#### Initialize After Media Source or MMP Initialization

Please initialize our SDK only after the media source or MMP data is initialized. This ensures that the media source data is sent correctly and prevents passing empty values.
{% endhint %}

Integrating the Tyrads offerwall functionality into your application is a straightforward process that involves a few key steps. By following these integration steps, you can seamlessly incorporate the offerwall feature, enhancing user engagement and potentially generating revenue for your application.

### 1. Initialization

Call `initialize` once, as early as possible in your app's lifecycle — typically in `application(_:didFinishLaunchingWithOptions:)` (UIKit) or your `App`'s `init`/`.task` (SwiftUI).

{% hint style="success" %}

### SDK Initialization best practices:

* **Initiate early:** It's advisable to initialize the SDK promptly after your app launches to ensure that all Tyr SDK functionalities are accessible when needed.
* **Initiate post-app authentication:** Re-initiate the SDK with current user details immediately after your user signs up or signs in to the app to update the user context.
* **Initiate periodically:** To optimize user experience, we strongly suggest invoking this method each time your app is brought to the foreground. This shouldn't impact your app's performance noticeably.
  {% endhint %}

This step initializes the Tyrads SDK within your application. You need to provide the API key and API secret obtained from the Tyrads platform. This allows your app to communicate securely with Tyrads' servers.

#### Basic Initialization

```swift
import TyradsSDKIOS

Tyrads.instance.initialize(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET"
)
```

#### Advanced Initialization (Personalized Rewards)

To maximize earnings and segment users, you can provide advanced user and media source information:

```swift
Tyrads.instance.initialize(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET",
    encryptionKey: "YOUR_32_BYTE_ENC_KEY", // Optional: enables secure mode
    engagementId: "123",                     // Optional: String
    placementId: "456",                      // Optional: String
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
        email: "user@example.com",
        phoneNumber: "001234567890",
        userGroup: "High purchase user",
        age: 28,
        gender: 1 // 1 = male, 2 = female
    ),
    config: TyradsConfig(skipInitialPages: false) // set true to skip the privacy gate
)
```

***

#### 1.1 Initialization Parameter Reference

{% hint style="warning" %}
To maximize the value to the user, sending us more data about the user and where they came from allows us to customize the reward experience. This can be used to provide feedback on the quality of users as well as customize the earnings journey of different segments of users.
{% endhint %}

The `initialize` method accepts several parameters to configure the SDK and enhance user attribution.

| Parameter | Type | Required | Description |
|---|---|:---:|---|
| `apiKey` | `String` | **Yes** | Your unique publisher identifier obtained from the Tyrads Dashboard. |
| `apiSecret` | `String` | **Yes** | Your publisher secret key used for secure server communication. |
| `encryptionKey` | `String` | No | **Encryption Key**: If provided, the SDK encrypts sensitive data during transmission. Recommended for high-security apps. |
| `engagementId` | `String` | No | Used to identify the engagement placement. |
| `placementId` | `String` | No | Used to differentiate between different coin placements within your app. |
| `mediaSourceInfo` | `TyradsMediaSourceInfo` | No | **Attribution Data**: Details about where the user came from (e.g. Facebook, Organic). Helps in tracking campaign performance. |
| `userInfo` | `TyradsUserInfo` | No | Metadata about the user (email, phone, user group) used for segmenting and personalizing offers. |
| `config` | `TyradsConfig` | No | SDK behavior settings, such as `skipInitialPages` to bypass the privacy/onboarding gate. |

***

#### Detailed Objects

**TyradsUserInfo**

Used to provide context about the current user for better offer matching and demographic targeting.

* **`email`**: User's email address.
* **`phoneNumber`**: User's contact number. Replace the leading `+` with `00`, e.g. `001234567890`.
* **`userGroup`**: A custom string to categorize users (e.g. `"VIP"`, `"High purchasing user"`). It also accepts a JSON-encoded string for structured groups (e.g. `"{\"tier\":\"vip\",\"segment\":\"high_spender\"}"`).
* **`age`**: The user's age (e.g. `28`).
* **`gender`**: The user's gender represented as an integer (`1` for Male, `2` for Female).

**TyradsMediaSourceInfo**

Essential for publishers who want to track the source of their users.

* `mediaSourceName`: The platform name (e.g. `"Facebook"`, `"GoogleAdWords"`).
* `mediaCampaignName`: The specific marketing campaign name.
* `mediaCreativeId`: The ID of the specific ad creative the user interacted with.
* `sub1` through `sub5`: Custom slots for any additional tracking parameters you require. `sub1`, `sub2`, and `sub5` are not returned on postback; `sub3` and `sub4` are.

***

### 2. User Authentication

Logging in the user is mandatory, and must be called after `initialize`. While providing a `userID` is optional, we **strongly recommend** using your own internal user ID to ensure progress is saved across device changes.

```swift
Task {
    // userID is your internal app identifier for the user
    let success = await Tyrads.instance.loginUser(userID: "my_unique_user_123")
}
```

{% hint style="warning" %}
If `userID` is omitted, the SDK falls back to whatever user ID it last stored on this device (via IDFA/IDFV-derived identification). If your app user resets their device's advertising identifier or reinstalls the app, that fallback identity is lost.

**If you send us your own `userID`, we save this and keep the user's progress even if their device identifier changes.**
{% endhint %}

***

### 3. Showing the Offerwall

Once initialized and logged in, you can display the Offerwall.

```swift
// Opens the default offers page
try? await Tyrads.instance.showOffers()

// Opens the offerwall with specific routing
try? await Tyrads.instance.showOffers(
    route: TyradsDeepRoutes.activeOffers
    // campaignID: 42 // Required for specific campaign routes
)

// Present from a specific view controller (optional — auto-detected if nil)
try? await Tyrads.instance.showOffers(from: self)
```

<details>

<summary><strong>Launch Mode</strong></summary>

The Tyrads SDK provides two primary ways to display the Offerwall to your users. You can configure this globally during initialization or override it for specific calls.

#### TyradsLaunchMode Types

| Mode | Description |
|---|---|
| `.webview` | **(Default)** Opens the Offerwall within an internal SDK-managed WebView inside your app. |
| `.externalBrowser` | Opens the Offerwall in the user's default system browser (Safari). |

***

#### 1. Global Configuration

Set the default launch behavior during SDK initialization:

```swift
Tyrads.instance.initialize(
    apiKey: "YOUR_API_KEY",
    apiSecret: "YOUR_API_SECRET",
    launchMode: .webview // Global default
)
```

#### 2. Manual Override

Override the global setting when calling `showOffers`:

```swift
// Force this specific opening to use the external browser
try? await Tyrads.instance.showOffers(launchMode: .externalBrowser)
```

#### 3. Dynamic Update

You can also change the global launch mode at any time after initialization:

```swift
Tyrads.instance.setLaunchMode(.externalBrowser)
```

***

{% hint style="warning" %}
**Safety & Integrity**: Even when using `.externalBrowser` mode, the SDK automatically performs all mandatory checks (Login, SDK Initialization, and Onboarding) before triggering the redirection. This ensures user tracking and campaign attribution remain 100% accurate.
{% endhint %}

</details>

#### Deep Link Routes

The Tyrads SDK supports deeplinking to specific sections of the offerwall. When calling `showOffers`, you can specify a route to open a particular page. For campaign-specific routes, you'll also need to provide a `campaignID`.

See [Deeplinking Routes](initialization/deeplinking-routes.md) for the full reference.

***

### 4. Premium Offers Widget

The **Premium Offers widget** is a standalone SwiftUI view that displays a preview of top offers. It is highly flexible and can be embedded anywhere in your UI.

```swift
import TyradsSDKIOS
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Recommended for you:")
            Tyrads.instance.topOffersWidget(widgetStyle: .sliderCards)
                .frame(minHeight: 160)
        }
    }
}
```

See [Premium Offers](initialization/premium-offers.md) for widget styles and details.

***

### 5. Localization

You can change the SDK language dynamically at runtime. This choice is persisted across app sessions.

```swift
Tyrads.instance.changeLanguage("id") // Indonesian
```

See [Localization](initialization/localization.md) for supported language codes and notes.

***

### 6. Push Notifications (APNs)

Tyrads delivers push notifications through APNs using your app's own APNs credentials, so enable the **Push Notifications** capability and provide your APNs key details to Tyrads before going live.

The SDK never requests push permission itself — your app owns that decision, same as it would for any of its own push notification needs. Forward APNs lifecycle events to the SDK from your `AppDelegate`.

See [Push Notifications](initialization/push-notifications.md) for the full setup.

***

### 7. Callbacks

Register callbacks to monitor user actions within the SDK:

```swift
Tyrads.instance.setCallback(.campaignActivated) { data in
    print("User activated a campaign:", data)
}

Tyrads.instance.setCallback(.campaignDetail) { data in
    print("User viewed campaign details:", data)
}

Tyrads.instance.setCallback(.campaignInstalled) { data in
    print("User installed a campaign:", data)
}
```

`data` is `[String: Any]` with campaign info.

***

### 8. Logout

```swift
Tyrads.instance.logoutUser()
```

Clears the stored session and resets login state. Call `loginUser` again to re-authenticate.

***

### 9. Manual Tracking

The SDK tracks core events (open, close, campaign actions) automatically. Use manual tracking for custom integration points:

```swift
Tyrads.instance.track(TyradsActivity.opened)
Tyrads.instance.track(TyradsActivity.closed)
Tyrads.instance.track(TyradsActivity.profileUpdated)
```
