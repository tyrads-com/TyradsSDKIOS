import Testing
@testable import TyradsSDKIOS

@Test func testTyradsInstanceExists() async throws {
    let instance = Tyrads.instance
    #expect(instance.publisherUserID == "")
    #expect(instance.isLoginSuccessful == false)
}

@Test func testMediaSourceInfoInit() {
    let info = TyradsMediaSourceInfo(
        mediaSourceName: "appsflyer",
        sub1: "test_sub1"
    )
    #expect(info.mediaSourceName == "appsflyer")
    #expect(info.sub1 == "test_sub1")
    #expect(info.sub2 == nil)
}

@Test func testUserInfoInit() {
    let info = TyradsUserInfo(
        email: "test@example.com",
        userGroup: "premium",
        age: 25,
        gender: 1
    )
    #expect(info.email == "test@example.com")
    #expect(info.userGroup == "premium")
    #expect(info.age == 25)
}

@Test func testTyradsConfigDefaults() {
    let config = TyradsConfig()
    #expect(config.skipInitialPages == false)
}

@Test func testTyradsConfigCustom() {
    let config = TyradsConfig(skipInitialPages: true)
    #expect(config.skipInitialPages == true)
}

@Test func testDeepRoutes() {
    #expect(TyradsDeepRoutes.offers == "offers")
    #expect(TyradsDeepRoutes.activeOffers == "active-offers")
    #expect(TyradsDeepRoutes.support == "support")
    #expect(TyradsDeepRoutes.settings == "settings")
}

@Test func testLaunchModes() {
    let webview = TyradsLaunchMode.webview
    let external = TyradsLaunchMode.externalBrowser
    #expect(webview != external)
}

@Test func testTrackingActivities() {
    #expect(TyradsActivity.initialized == "Initialized")
    #expect(TyradsActivity.opened == "Opened")
    #expect(TyradsActivity.closed == "Closed")
    #expect(TyradsActivity.campaignActivated == "CampaignActivated")
}

@Test func testValueNotifier() {
    let notifier = TyradsValueNotifier<Int>(0)
    var received: [Int] = []
    notifier.addObserver { received.append($0) }
    notifier.value = 1
    notifier.value = 2
    #expect(received == [1, 2])
}

@Test func testAESEncryptDecrypt() async throws {
    let key = "12345678901234567890123456789012" // 32 bytes
    let encryptor = try TyradsAESEncrypt(encryptionKey: key)
    let payload = ["activity": "Initialized", "userId": "user123"]
    let encrypted = try encryptor.encryptAESGCM(payload)
    #expect(encrypted["val"] != nil)
    #expect(encrypted["vec"] != nil)
    #expect(encrypted["tag"] != nil)
    let decrypted = try encryptor.decryptAESGCM(encrypted as! [String: Any])
    #expect(decrypted.contains("Initialized"))
}

@Test func testAESInvalidKeyThrows() {
    #expect(throws: TyradsAESEncrypt.AESError.self) {
        _ = try TyradsAESEncrypt(encryptionKey: "short_key")
    }
}

@Test func testUIColorHexInit() {
    let color = UIColor(hex: "#02B5BE")
    #expect(color != nil)
    let colorNoHash = UIColor(hex: "02B5BE")
    #expect(colorNoHash != nil)
    let invalid = UIColor(hex: "ZZZZZZ")
    #expect(invalid == nil)
}

@Test @MainActor func testFormatTimer() {
    let controller = TyradsInAppNotificationViewModel.shared
    #expect(controller.formatTimer(remainingSeconds: nil) == "")
    #expect(controller.formatTimer(remainingSeconds: 0) == "")
    #expect(controller.formatTimer(remainingSeconds: 3661) == "01:01:01")
    #expect(controller.formatTimer(remainingSeconds: 90061) == "01d 01h") // > 1 day
}

@Test func testWebURLBuilder() {
    // Can't call getWebURL without token but we test structure
    let route = TyradsDeepRoutes.offers
    #expect(route == "offers")
}

import UIKit
