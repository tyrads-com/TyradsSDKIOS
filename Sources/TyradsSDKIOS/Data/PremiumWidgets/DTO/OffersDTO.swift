import Foundation

// MARK: - Network DTOs (Data)
// Response envelopes. Stay in the Data layer — Domain never sees them.

struct TyradsOffersResponse: Codable {
    let code: Int
    let data: [TyradsOfferModel]
    let message: String
    let timestamp: Int
    let responseTime: Double
}

struct TyradsEngagementResponse: Codable {
    let data: TyradsEngagementData?
    let message: String?
}

struct TyradsEngagementData: Codable {
    let currencySales: TyradsCurrencySales?

    enum CodingKeys: String, CodingKey {
        case currencySales = "CurrencySales"
    }
}
