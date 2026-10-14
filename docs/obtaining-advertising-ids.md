# Obtaining Advertising ID's

**iOS 14+**

You need to add `NSUserTrackingUsageDescription` to your `Info.plist` file:

```
<key>NSUserTrackingUsageDescription</key>
<string>We use device identification to personalize your rewards experience, track your progress, and provide tailored offers. This helps us improve our services and ensure you get the most value from our rewards program.</string>
```

**Request IDFA Permission**

The Tyrads SDK automatically requests App Tracking Transparency (ATT) authorization on your behalf during login — you don't need to call `ATTrackingManager` yourself.

The SDK can work with or without IDFA permission on iOS 14+:

* If ATT authorization is **granted**, the SDK uses the device's **IDFA** (Identifier for Advertisers) for attribution.
* If ATT authorization is **denied or restricted**, the SDK falls back to the device's **IDFV** (Identifier for Vendor), and the offerwall serves non-personalized offers. Conversion is expected to be lower in this scenario.

Offerwall integrations perform better when IDFA permission is granted. Our recommendation is that you add the `NSUserTrackingUsageDescription` string above so the ATT prompt can be shown, and consider requesting tracking permission early in your app's flow — before `loginUser()` is called — for the best attribution accuracy.
