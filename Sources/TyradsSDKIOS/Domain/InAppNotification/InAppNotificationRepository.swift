import Foundation

// MARK: - In-app notification boundary (Domain)

protocol TyradsInAppNotificationRepository {
    func getActiveCampaignGroups() async throws -> [TyradsActiveOfferGroup]
    func getCurrencySales() async throws -> TyradsCurrencySales?
}
