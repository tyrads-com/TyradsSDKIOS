import Foundation

// MARK: - LoadInAppPromotionsUseCase (Domain)
// Loads active campaigns + currency sale concurrently and applies the
// "hotdeals with pending limited-time events" filtering rule.

public struct TyradsInAppPromotions {
    public let activeOffers: [TyradsActiveCampaign]
    public let currencySales: TyradsCurrencySales?
    public let currencySaleMultiplier: Double?
    public let currencySaleRemainingSeconds: Int
}

struct TyradsLoadInAppPromotionsUseCase {
    let repository: TyradsInAppNotificationRepository

    func callAsFunction() async -> TyradsInAppPromotions {
        let groups = (try? await repository.getActiveCampaignGroups()) ?? []
        let sales = try? await repository.getCurrencySales()

        return TyradsInAppPromotions(
            activeOffers: filterLimitedOffersWithEvents(groups),
            currencySales: sales,
            currencySaleMultiplier: sales?.multiplier,
            currencySaleRemainingSeconds: sales?.remainingTimeSeconds ?? 0
        )
    }

    private func filterLimitedOffersWithEvents(_ groups: [TyradsActiveOfferGroup]) -> [TyradsActiveCampaign] {
        var seen = Set<Int>()
        return groups
            .filter { $0.groupName.lowercased() == "hotdeals" }
            .flatMap { $0.campaigns }
            .filter { !$0.limitedTimeEvents.isEmpty }
            .filter { $0.campaignStatus.lowercased() != "suspended" && $0.validity.isInstalled }
            .filter { campaign in
                campaign.limitedTimeEvents.contains { $0.conversionStatus?.lowercased() != "approved" }
            }
            .filter { seen.insert($0.campaignId).inserted }
    }
}
