import Foundation

public struct TyradsActiveOffersModel: Codable {
    public let data: [TyradsActiveOfferGroup]
    public let message: String

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        data = try c.decodeIfPresent([TyradsActiveOfferGroup].self, forKey: .data) ?? []
        message = try c.decodeIfPresent(String.self, forKey: .message) ?? ""
    }
}

public struct TyradsActiveOfferGroup: Codable {
    public let groupName: String
    public let availableCurrencies: [String: TyradsActiveCurrency]
    public let campaigns: [TyradsActiveCampaign]

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        groupName = try c.decodeIfPresent(String.self, forKey: .groupName) ?? ""
        availableCurrencies = try c.decodeIfPresent([String: TyradsActiveCurrency].self, forKey: .availableCurrencies) ?? [:]
        campaigns = try c.decodeIfPresent([TyradsActiveCampaign].self, forKey: .campaigns) ?? []
    }
}

public struct TyradsActiveCurrency: Codable {
    public let currencyId: Int
    public let currencyIcon: String
    public let currencyName: String

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currencyId = try c.decodeIfPresent(Int.self, forKey: .currencyId) ?? 0
        currencyIcon = try c.decodeIfPresent(String.self, forKey: .currencyIcon) ?? ""
        currencyName = try c.decodeIfPresent(String.self, forKey: .currencyName) ?? ""
    }
}

public struct TyradsActiveCampaign: Codable, Hashable {
    public let campaignId: Int
    public let campaignName: String
    public let campaignDescription: String
    public let campaignType: String
    public let campaignPremium: Bool
    public let validity: TyradsActiveValidity
    public let availableCurrencies: [String: TyradsActiveCurrency]
    public let app: TyradsActiveApp
    public let campaignStatus: String
    public let limitedTimeEvents: [TyradsPayoutEvent]

    public static func == (lhs: TyradsActiveCampaign, rhs: TyradsActiveCampaign) -> Bool {
        lhs.campaignId == rhs.campaignId
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(campaignId)
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        campaignId = try c.decodeIfPresent(Int.self, forKey: .campaignId) ?? 0
        campaignName = try c.decodeIfPresent(String.self, forKey: .campaignName) ?? ""
        campaignDescription = try c.decodeIfPresent(String.self, forKey: .campaignDescription) ?? ""
        campaignType = try c.decodeIfPresent(String.self, forKey: .campaignType) ?? ""
        campaignPremium = try c.decodeIfPresent(Bool.self, forKey: .campaignPremium) ?? false
        validity = try c.decodeIfPresent(TyradsActiveValidity.self, forKey: .validity) ?? TyradsActiveValidity()
        availableCurrencies = try c.decodeIfPresent([String: TyradsActiveCurrency].self, forKey: .availableCurrencies) ?? [:]
        app = try c.decodeIfPresent(TyradsActiveApp.self, forKey: .app) ?? TyradsActiveApp()
        campaignStatus = try c.decodeIfPresent(String.self, forKey: .campaignStatus) ?? ""
        limitedTimeEvents = try c.decodeIfPresent([TyradsPayoutEvent].self, forKey: .limitedTimeEvents) ?? []
    }
}

public struct TyradsActiveValidity: Codable {
    public let isRetryDownload: Bool
    public let isActivated: Bool
    public let isOldUser: Bool
    public let isInstalled: Bool
    public let capReached: Bool

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isRetryDownload = try c.decodeIfPresent(Bool.self, forKey: .isRetryDownload) ?? false
        isActivated = try c.decodeIfPresent(Bool.self, forKey: .isActivated) ?? false
        isOldUser = try c.decodeIfPresent(Bool.self, forKey: .isOldUser) ?? false
        isInstalled = try c.decodeIfPresent(Bool.self, forKey: .isInstalled) ?? false
        capReached = try c.decodeIfPresent(Bool.self, forKey: .capReached) ?? false
    }

    public init() {
        isRetryDownload = false; isActivated = false; isOldUser = false
        isInstalled = false; capReached = false
    }
}

public struct TyradsActiveApp: Codable {
    public let id: Int
    public let title: String
    public let thumbnail: String
    public let previewUrl: String
    public let storeCategory: String

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(Int.self, forKey: .id) ?? 0
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        thumbnail = try c.decodeIfPresent(String.self, forKey: .thumbnail) ?? ""
        previewUrl = try c.decodeIfPresent(String.self, forKey: .previewUrl) ?? ""
        storeCategory = try c.decodeIfPresent(String.self, forKey: .storeCategory) ?? ""
    }

    public init() {
        id = 0; title = ""; thumbnail = ""; previewUrl = ""; storeCategory = ""
    }
}

public struct TyradsActivePayoutInfo: Codable {
    public let currencyId: Int
    public let currencyName: String
    public let currencyIcon: String
    public let currencyConversionRate: Double
    public let payoutAmountConverted: Double

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currencyId = try c.decodeIfPresent(Int.self, forKey: .currencyId) ?? 0
        currencyName = try c.decodeIfPresent(String.self, forKey: .currencyName) ?? ""
        currencyIcon = try c.decodeIfPresent(String.self, forKey: .currencyIcon) ?? ""
        currencyConversionRate = try c.decodeIfPresent(Double.self, forKey: .currencyConversionRate) ?? 0
        payoutAmountConverted = try c.decodeIfPresent(Double.self, forKey: .payoutAmountConverted) ?? 0
    }
}

public struct TyradsPayoutEvent: Codable {
    public let appEventId: Int
    public let conversionStatus: String?
    public let identifier: String
    public let eventName: String
    public let payoutInfo: [String: TyradsActivePayoutInfo]
    public let allowDuplicateEvents: Bool
    public let maxTime: Int
    public let limitedTimeEventRemainingSeconds: Double
    public let isLimitedTimeEvent: Bool
    public let dailyCount: Int
    public let dailyLimit: Int?
    public let count: Int
    public let limit: Int?

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appEventId = try c.decodeIfPresent(Int.self, forKey: .appEventId) ?? 0
        conversionStatus = try c.decodeIfPresent(String.self, forKey: .conversionStatus)
        identifier = try c.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        eventName = try c.decodeIfPresent(String.self, forKey: .eventName) ?? ""
        payoutInfo = try c.decodeIfPresent([String: TyradsActivePayoutInfo].self, forKey: .payoutInfo) ?? [:]
        allowDuplicateEvents = try c.decodeIfPresent(Bool.self, forKey: .allowDuplicateEvents) ?? false
        maxTime = try c.decodeIfPresent(Int.self, forKey: .maxTime) ?? 0
        limitedTimeEventRemainingSeconds = try c.decodeIfPresent(Double.self, forKey: .limitedTimeEventRemainingSeconds) ?? 0
        isLimitedTimeEvent = try c.decodeIfPresent(Bool.self, forKey: .isLimitedTimeEvent) ?? false
        dailyCount = try c.decodeIfPresent(Int.self, forKey: .dailyCount) ?? 0
        dailyLimit = try c.decodeIfPresent(Int.self, forKey: .dailyLimit)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 0
        limit = try c.decodeIfPresent(Int.self, forKey: .limit)
    }
}
