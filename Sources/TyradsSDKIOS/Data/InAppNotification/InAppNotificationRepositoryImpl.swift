import Foundation

// MARK: - InAppNotificationRepositoryImpl (Data)

final class TyradsInAppNotificationRepositoryImpl: TyradsInAppNotificationRepository {
    private let network: TyradsNetworkClient
    private let session: TyradsSessionStore

    init(network: TyradsNetworkClient = TyradsNetworkManager.shared,
         session: TyradsSessionStore = .shared) {
        self.network = network
        self.session = session
    }

    func getActiveCampaignGroups() async throws -> [TyradsActiveOfferGroup] {
        let model: TyradsActiveOffersModel = try await network.request(
            endpoint: TyradsEndpointNames.activeOffers,
            method: "GET",
            body: nil,
            queryParams: ["lang": session.language]
        )
        return model.data
    }

    func getCurrencySales() async throws -> TyradsCurrencySales? {
        let response: TyradsEngagementResponse = try await network.request(
            endpoint: TyradsEndpointNames.engagement,
            method: "GET",
            body: nil,
            queryParams: ["lang": session.language]
        )
        return response.data?.currencySales
    }
}
