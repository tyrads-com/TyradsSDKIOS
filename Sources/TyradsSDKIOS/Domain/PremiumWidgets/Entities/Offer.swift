import Foundation

// MARK: - Offer entity (Domain)
// Pure domain model. No networking concerns. Public so SDK consumers can read it.

public struct TyradsOfferModel: Codable, Identifiable {
    public let campaignId: Int
    public let campaignName: String
    public let campaignDescription: String
    public let campaignType: String
    public let campaignPremium: Bool
    public let campaignStatus: String
    public let validity: TyradsOfferValidity
    public let availableCurrencies: [String: TyradsAvailableCurrency]
    public let app: TyradsOfferApp
    public let targeting: TyradsOfferTargeting
    public let payoutSummary: [String: TyradsPayoutSummary]
    public let tracking: TyradsOfferTracking
    public let creative: TyradsCreative
    public let hasPlaytimeEvents: Bool

    public var id: Int { campaignId }

    enum CodingKeys: String, CodingKey {
        case campaignId, campaignName, campaignDescription, campaignType
        case campaignPremium, campaignStatus, validity, availableCurrencies
        case app, targeting, payoutSummary, tracking, creative, hasPlaytimeEvents
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        campaignId = try c.decode(Int.self, forKey: .campaignId)
        campaignName = try c.decode(String.self, forKey: .campaignName)
        campaignDescription = try c.decodeIfPresent(String.self, forKey: .campaignDescription) ?? ""
        campaignType = try c.decodeIfPresent(String.self, forKey: .campaignType) ?? ""
        campaignPremium = try c.decodeIfPresent(Bool.self, forKey: .campaignPremium) ?? false
        campaignStatus = try c.decodeIfPresent(String.self, forKey: .campaignStatus) ?? ""
        validity = try c.decode(TyradsOfferValidity.self, forKey: .validity)
        availableCurrencies = try c.decodeIfPresent([String: TyradsAvailableCurrency].self, forKey: .availableCurrencies) ?? [:]
        app = try c.decode(TyradsOfferApp.self, forKey: .app)
        targeting = try c.decode(TyradsOfferTargeting.self, forKey: .targeting)
        payoutSummary = try c.decodeIfPresent([String: TyradsPayoutSummary].self, forKey: .payoutSummary) ?? [:]
        tracking = try c.decode(TyradsOfferTracking.self, forKey: .tracking)
        creative = try c.decode(TyradsCreative.self, forKey: .creative)
        hasPlaytimeEvents = try c.decodeIfPresent(Bool.self, forKey: .hasPlaytimeEvents) ?? false
    }
}

public struct TyradsOfferValidity: Codable {
    public let isRetryDownload: Bool
    public let isActivated: Bool
    public let isOldUser: Bool
    public let expiredOn: String?
    public let expiredInSeconds: Int?
    public let isInstalled: Bool

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isRetryDownload = try c.decodeIfPresent(Bool.self, forKey: .isRetryDownload) ?? false
        isActivated = try c.decodeIfPresent(Bool.self, forKey: .isActivated) ?? false
        isOldUser = try c.decodeIfPresent(Bool.self, forKey: .isOldUser) ?? false
        expiredOn = try c.decodeIfPresent(String.self, forKey: .expiredOn)
        expiredInSeconds = try c.decodeIfPresent(Int.self, forKey: .expiredInSeconds)
        isInstalled = try c.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
    }
}

public struct TyradsAvailableCurrency: Codable {
    public let currencyId: Int
    public let currencyIcon: String
    public let currencyName: String
}

public struct TyradsPayoutSummary: Codable {
    public let totalPayoutConverted: Double
    public let totalPlayablePayoutConverted: Double
    public let totalMicrochargePayoutConverted: Double

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalPayoutConverted = try c.decodeIfPresent(Double.self, forKey: .totalPayoutConverted) ?? 0
        totalPlayablePayoutConverted = try c.decodeIfPresent(Double.self, forKey: .totalPlayablePayoutConverted) ?? 0
        totalMicrochargePayoutConverted = try c.decodeIfPresent(Double.self, forKey: .totalMicrochargePayoutConverted) ?? 0
    }
}

public struct TyradsCreative: Codable {
    public let creativeUrl: String
    public let creativePacks: [TyradsCreativePack]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        creativeUrl = try c.decodeIfPresent(String.self, forKey: .creativeUrl) ?? ""
        creativePacks = try c.decodeIfPresent([TyradsCreativePack].self, forKey: .creativePacks) ?? []
    }
}

public struct TyradsCreativePack: Codable {
    public let creativePackId: Int
    public let creativePackName: String
    public let languageName: String
    public let languageCode: String
    public let creatives: [TyradsCreativeItem]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        creativePackId = try c.decode(Int.self, forKey: .creativePackId)
        creativePackName = try c.decode(String.self, forKey: .creativePackName)
        languageName = try c.decode(String.self, forKey: .languageName)
        languageCode = try c.decode(String.self, forKey: .languageCode)
        creatives = try c.decodeIfPresent([TyradsCreativeItem].self, forKey: .creatives) ?? []
    }
}

public struct TyradsCreativeItem: Codable {
    public let creativeId: Int
    public let creativeName: String
    public let callToAction: String?
    public let text: String
    public let fileUrl: String
    public let creativeType: TyradsCreativeType

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        creativeId = try c.decode(Int.self, forKey: .creativeId)
        creativeName = try c.decode(String.self, forKey: .creativeName)
        callToAction = try c.decodeIfPresent(String.self, forKey: .callToAction)
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        fileUrl = try c.decodeIfPresent(String.self, forKey: .fileUrl) ?? ""
        creativeType = try c.decode(TyradsCreativeType.self, forKey: .creativeType)
    }
}

public struct TyradsCreativeType: Codable {
    public let name: String
    public let type: String
    public let width: String
    public let height: String
    public let creativeCategoryType: String
}

public struct TyradsOfferTargeting: Codable {
    public let os: String?
    public let targetingType: String
    public let reward: TyradsReward?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        os = try c.decodeIfPresent(String.self, forKey: .os)
        targetingType = try c.decodeIfPresent(String.self, forKey: .targetingType) ?? ""
        reward = try c.decodeIfPresent(TyradsReward.self, forKey: .reward)
    }
}

public struct TyradsOfferTracking: Codable {
    public let attributionTool: String?
    public let clickUrl: String?
    public let impressionUrl: String?
    public let s2sClickUrl: String?
}

public struct TyradsOfferApp: Codable {
    public let id: Int
    public let title: String
    public let packageName: String
    public let rating: Double
    public let previewUrl: String
    public let shortDescription: String
    public let store: String
    public let storeCategory: String
    public let thumbnail: String

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        packageName = try c.decodeIfPresent(String.self, forKey: .packageName) ?? ""
        rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        previewUrl = try c.decodeIfPresent(String.self, forKey: .previewUrl) ?? ""
        shortDescription = try c.decodeIfPresent(String.self, forKey: .shortDescription) ?? ""
        store = try c.decodeIfPresent(String.self, forKey: .store) ?? ""
        storeCategory = try c.decodeIfPresent(String.self, forKey: .storeCategory) ?? ""
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
    }
}

public struct TyradsReward: Codable {
    public let rewardDifficulty: String
    public let incentRewardDescription: String

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rewardDifficulty = try c.decodeIfPresent(String.self, forKey: .rewardDifficulty) ?? ""
        incentRewardDescription = try c.decodeIfPresent(String.self, forKey: .incentRewardDescription) ?? ""
    }
}
