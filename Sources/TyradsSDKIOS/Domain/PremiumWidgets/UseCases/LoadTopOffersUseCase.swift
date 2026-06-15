import Foundation

// MARK: - LoadTopOffersUseCase (Domain)
// Fetches offers + sale + active count concurrently, then applies the
// business rule: premium first, top 5.

public struct TyradsTopOffers {
    public let offers: [TyradsOfferModel]
    public let currencySales: TyradsCurrencySales?
    public let activatedCount: Int
}

struct TyradsLoadTopOffersUseCase {
    let repository: TyradsOffersRepository

    func callAsFunction() async throws -> TyradsTopOffers {
        let fetched = try await repository.getOffers()
        let currencySales = try await repository.getCurrencySales()
        let activatedCount = try await repository.getActivatedOfferCount()

        let topOffers = fetched
            .sorted { ($0.campaignPremium ? 1 : 0) > ($1.campaignPremium ? 1 : 0) }
            .prefix(5)

        return TyradsTopOffers(
            offers: Array(topOffers),
            currencySales: currencySales,
            activatedCount: activatedCount
        )
    }
}
