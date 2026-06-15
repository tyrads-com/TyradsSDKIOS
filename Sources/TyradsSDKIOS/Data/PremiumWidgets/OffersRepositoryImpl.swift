import Foundation

// MARK: - OffersRepositoryImpl (Data)
// Implements the Domain boundary using the network client. Maps DTOs to
// domain entities and keeps all endpoint/transport details here.

final class TyradsOffersRepositoryImpl: TyradsOffersRepository {
    private let network: TyradsNetworkManager

    init(network: TyradsNetworkManager = .shared) {
        self.network = network
    }

    private var lang: String { Tyrads.instance.selectedLanguage }

    func getOffers() async throws -> [TyradsOfferModel] {
        let response: TyradsOffersResponse = try await network.request(
            endpoint: TyradsEndpointNames.offers,
            queryParams: ["lang": lang]
        )
        return response.data
    }

    func getCurrencySales() async throws -> TyradsCurrencySales? {
        let response: TyradsEngagementResponse = try await network.request(
            endpoint: TyradsEndpointNames.engagement,
            queryParams: ["lang": lang]
        )
        return response.data?.currencySales
    }

    func getActivatedOfferCount() async throws -> Int {
        let data = try await network.requestData(
            endpoint: TyradsEndpointNames.offerSummary,
            queryParams: ["lang": lang]
        )
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataObj = json["data"] as? [String: Any],
           let count = dataObj["activeCampaignCount"] as? Int {
            return count
        }
        return 0
    }

    func activateOffer(id: Int) async throws {
        _ = try await network.requestData(
            endpoint: "\(TyradsEndpointNames.offers)/\(id)/activate",
            method: "POST"
        )
    }

    func pingS2S(url: URL) async {
        _ = try? await URLSession.shared.data(from: url)
    }
}
