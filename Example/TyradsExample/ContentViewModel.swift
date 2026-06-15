import SwiftUI
import TyradsSDKIOS

// MARK: - ContentViewModel (MVVM)
// Owns all config/init/login state and actions. The View stays declarative.

@MainActor
final class ContentViewModel: ObservableObject {

    struct ConfigOption: Identifiable {
        let label: String
        let value: String
        var id: String { value }
    }

    let configOptions: [ConfigOption] = [
        .init(label: "Tyrreward", value: "tyrreward"),
        .init(label: "Belanda 1", value: "belanda1"),
        .init(label: "Belanda 2", value: "belanda2"),
        .init(label: "Belanda 3", value: "belanda3"),
    ]

    @Published var selectedConfig = "belanda1"
    @Published var apiKey = ""
    @Published var apiSecret = ""
    @Published var encKey = ""
    @Published var engagementId = ""
    @Published var placementId = ""
    @Published var userId = ""
    @Published var selectedAge: Int?
    @Published var selectedGender: Int?
    @Published var isLoading = false
    @Published var isInitialized = false
    @Published var widgetIsSlider: Bool = true
    var widgetStyle: TyradsPremiumWidgetStyle { widgetIsSlider ? .sliderCards : .list }

    private let prefs = UserDefaults.standard
    private var didLoad = false

    var genderLabel: String {
        switch selectedGender {
        case 1: return "Male"
        case 2: return "Female"
        default: return "Gender: Any"
        }
    }

    // MARK: Config keys

    private func configKeys(for config: String) -> (apiKey: String, apiSecret: String, encKey: String) {
        switch config {
        case "tyrreward": return (Env.IOS_TYRREWARD_SDK_KEY, Env.IOS_TYRREWARD_SDK_SECRET, Env.IOS_TYRREWARD_SDK_ENC_KEY)
        case "belanda2":  return (Env.IOS_BELANDA2_TYRADS_SDK_KEY, Env.IOS_BELANDA2_TYRADS_SDK_SECRET, Env.IOS_BELANDA2_TYRADS_SDK_ENC_KEY)
        case "belanda3":  return (Env.IOS_BELANDA3_TYRADS_SDK_KEY, Env.IOS_BELANDA3_TYRADS_SDK_SECRET, Env.IOS_BELANDA3_TYRADS_SDK_ENC_KEY)
        default:          return (Env.IOS_BELANDA1_TYRADS_SDK_KEY, Env.IOS_BELANDA1_TYRADS_SDK_SECRET, Env.IOS_BELANDA1_TYRADS_SDK_ENC_KEY)
        }
    }

    // MARK: Actions

    func onConfigChanged(_ newValue: String) {
        let keys = configKeys(for: newValue)
        apiKey = keys.apiKey
        apiSecret = keys.apiSecret
        encKey = keys.encKey
        isInitialized = false
        initializeTyrads()
    }

    func loadStoredAndInit() {
        guard !didLoad else { return }
        didLoad = true
        let saved = prefs.string(forKey: "selectedConfig") ?? "belanda1"
        selectedConfig = saved
        let keys = configKeys(for: saved)
        apiKey = keys.apiKey
        apiSecret = keys.apiSecret
        encKey = keys.encKey
        initializeTyrads()
    }

    func initializeTyrads() {
        let keys = configKeys(for: selectedConfig)
        let finalKey    = nonEmpty(apiKey)    ?? keys.apiKey
        let finalSecret = nonEmpty(apiSecret) ?? keys.apiSecret
        let finalEncKey = nonEmpty(encKey)    ?? keys.encKey
        let finalUserId = nonEmpty(userId)    ?? prefs.string(forKey: "tyrads_user_id") ?? "aatest_01"

        prefs.set(selectedConfig, forKey: "selectedConfig")

        Tyrads.instance.initialize(
            apiKey: finalKey,
            apiSecret: finalSecret,
            encryptionKey: finalEncKey.isEmpty ? nil : finalEncKey,
            engagementId: nonEmpty(engagementId),
            placementId: nonEmpty(placementId),
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
                email: "example@tyrads.com",
                phoneNumber: "001234567890",
                userGroup: "High purchase user",
                age: selectedAge,
                gender: selectedGender
            ),
            config: TyradsConfig(skipInitialPages: true)
        )

        Task {
            await Tyrads.instance.loginUser(userID: finalUserId)
            prefs.set(finalUserId, forKey: "tyrads_user_id")
            Tyrads.instance.setCallback(.campaignDetail) { data in print("[Example] campaignDetail: \(data)") }
            Tyrads.instance.setCallback(.campaignActivated) { data in print("[Example] campaignActivated: \(data)") }
        }

        isInitialized = true
    }

    func showOfferwall() {
        guard !isLoading else { return }
        isLoading = true

        if !isInitialized {
            initializeTyrads()
        }

        Task {
            _ = await Tyrads.instance.waitAndCheck()
            isLoading = false
            try? await Tyrads.instance.showOffers()
        }
    }

    private func nonEmpty(_ s: String) -> String? {
        s.trimmingCharacters(in: .whitespaces).isEmpty ? nil : s
    }
}
