/**
 TyradsSDKIOS — Integration Example
 ====================================

 STEP 1: AppDelegate setup
 --------------------------
 import TyradsSDKIOS

 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {

     func application(_ application: UIApplication,
                      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

         Tyrads.instance.initialize(
             apiKey: "YOUR_API_KEY",
             apiSecret: "YOUR_API_SECRET",
             // Optional params:
             engagementId: "123",
             placementId: "456",
             mediaSourceInfo: TyradsMediaSourceInfo(
                 mediaSourceName: "appsflyer",
                 mediaCampaignName: "summer_2025",
                 sub1: "custom_sub1"
             ),
             userInfo: TyradsUserInfo(
                 email: "user@example.com",
                 userGroup: "premium"
             ),
             config: TyradsConfig(skipInitialPages: false),
             launchMode: .webview
         )

         return true
     }

     // Forward APNs callbacks to TyradsAPNsManager
     func application(_ application: UIApplication,
                      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         TyradsAPNsManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
     }

     func application(_ application: UIApplication,
                      didFailToRegisterForRemoteNotificationsWithError error: Error) {
         TyradsAPNsManager.shared.didFailToRegisterForRemoteNotifications(error: error)
     }

     func application(_ application: UIApplication,
                      didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                      fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
         TyradsAPNsManager.shared.didReceiveRemoteNotification(
             userInfo: userInfo,
             fetchCompletionHandler: completionHandler
         )
     }
 }


 STEP 2: Login user (call after SDK init, e.g. after user signs in to your app)
 -------------------------------------------------------------------------------
 Task {
     let success = await Tyrads.instance.loginUser(userID: "user123")
     if success {
         print("Tyrads login successful")
     }
 }


 STEP 3: Show offerwall
 ----------------------
 // From a UIViewController:
 @IBAction func showOfferwallTapped(_ sender: UIButton) {
     Task {
         try? await Tyrads.instance.showOffers(from: self)
     }
 }

 // With specific campaign:
 Task {
     try? await Tyrads.instance.showOffers(
         campaignID: 789,
         route: TyradsDeepRoutes.offers,
         launchMode: .webview,
         from: self
     )
 }

 // Open in external Safari:
 Task {
     try? await Tyrads.instance.showOffers(launchMode: .externalBrowser, from: self)
 }


 STEP 4: Premium Offers Widget (SwiftUI)
 ----------------------------------------
 import SwiftUI
 import TyradsSDKIOS

 struct ContentView: View {
     var body: some View {
         VStack {
             Text("Earn rewards!")
                 .font(.headline)

             TyradsPremiumOffersView()
                 .frame(height: 160)
         }
     }
 }


 STEP 5: Premium Offers Widget (UIKit)
 ---------------------------------------
 // Embed TyradsPremiumOffersViewController as a child VC:
 let offersVC = TyradsPremiumOffersViewController()
 addChild(offersVC)
 offersVC.view.translatesAutoresizingMaskIntoConstraints = false
 view.addSubview(offersVC.view)
 NSLayoutConstraint.activate([
     offersVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
     offersVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
     offersVC.view.heightAnchor.constraint(equalToConstant: 160),
     offersVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
 ])
 offersVC.didMove(toParent: self)


 STEP 6: Callbacks
 ------------------
 Tyrads.instance.setCallback(.campaignActivated) { data in
     print("Campaign activated: \(data)")
     // data keys: campaignId, campaignName, appId, appName, appCategory, clickUrl, s2sClickUrl
 }

 Tyrads.instance.setCallback(.campaignDetail) { data in
     print("Campaign detail viewed: \(data)")
 }


 STEP 7: Language
 -----------------
 // Supported: en, es, id, ja, ko, zh-Hans-CN
 Tyrads.instance.changeLanguage("id")


 STEP 8: Logout
 ---------------
 Tyrads.instance.logoutUser()


 STEP 9: Deep link observation
 ------------------------------
 Tyrads.instance.deepLinkNotifier.addObserver { deepLink in
     guard let deepLink else { return }
     print("Deep link received: \(deepLink)")
     // Navigate accordingly
 }
 */

// This file is documentation-only. No executable code.
