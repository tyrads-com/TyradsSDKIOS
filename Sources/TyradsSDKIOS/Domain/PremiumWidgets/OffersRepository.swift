import Foundation

// MARK: - Repository boundary (Domain)
// Domain owns the interface. Data layer provides the implementation.
// Dependency points inward: Data -> Domain.

protocol TyradsOffersRepository {
    func getOffers() async throws -> [TyradsOfferModel]
    func getCurrencySales() async throws -> TyradsCurrencySales?
    func getActivatedOfferCount() async throws -> Int
    func activateOffer(id: Int) async throws
    /// Fire-and-forget server-to-server click ping.
    func pingS2S(url: URL) async
}
