import Foundation
import UIKit

// MARK: - PremiumWidgetsViewModel (Presentation / MVVM)
// Holds widget UI state and the cache/dedupe policy. Delegates all business
// rules to use cases. Shared instance keeps the widget's offer cache alive
// across view re-creations and lets the SDK trigger a language refresh.

@MainActor
public final class TyradsPremiumWidgetsViewModel: ObservableObject {
    public static let shared = TyradsPremiumWidgetsViewModel()

    @Published public private(set) var offers: [TyradsOfferModel] = []
    @Published public private(set) var activatedCount: Int = 0
    @Published public private(set) var currencySales: TyradsCurrencySales?
    @Published public private(set) var isLoading: Bool = true
    /// Campaign id whose Play/Install action is currently running, for per-item spinners.
    @Published public private(set) var loadingCampaignId: Int?

    public private(set) var reloadAfterOfferActivation = false
    public private(set) var redirectToActivePage = false

    private let loadUseCase: TyradsLoadTopOffersUseCase
    private let openUseCase: TyradsOpenOfferUseCase

    // Cache policy
    private var lastFetchTime: Date?
    private let cacheTTL: TimeInterval = 300
    private let minRefreshInterval: TimeInterval = 60
    private var ongoingTask: Task<TyradsTopOffers, Error>?
    private var offerOpening = false

    init(repository: TyradsOffersRepository = TyradsOffersRepositoryImpl()) {
        self.loadUseCase = TyradsLoadTopOffersUseCase(repository: repository)
        self.openUseCase = TyradsOpenOfferUseCase(repository: repository, events: TyradsFacadeOfferEventSink())
    }

    public func load(force: Bool = false) async {
        if !force, let last = lastFetchTime,
           Date().timeIntervalSince(last) < cacheTTL, !offers.isEmpty {
            return
        }
        if let ongoing = ongoingTask {
            if force {
                ongoing.cancel()
                ongoingTask = nil
            } else {
                _ = try? await ongoing.value
                return
            }
        }
        if !force, let last = lastFetchTime,
           Date().timeIntervalSince(last) < minRefreshInterval {
            return
        }

        isLoading = offers.isEmpty

        let task = Task { [weak self] () -> TyradsTopOffers in
            guard let self else {
                return TyradsTopOffers(offers: [], currencySales: nil, activatedCount: 0)
            }
            guard await Tyrads.instance.waitAndCheck() else {
                return TyradsTopOffers(
                    offers: await self.offers,
                    currencySales: await self.currencySales,
                    activatedCount: await self.activatedCount
                )
            }
            return try await self.loadUseCase()
        }
        ongoingTask = task

        do {
            let result = try await task.value
            offers = result.offers
            currencySales = result.currencySales
            activatedCount = result.activatedCount
            lastFetchTime = Date()
            isLoading = false
            ongoingTask = nil
        } catch is CancellationError {
            // iOS 15 NavigationView bug: outer .task can be cancelled and
            // restarted while the inner unstructured task is still running.
            // Do NOT clear ongoingTask or flip isLoading — the next load()
            // call will find the ongoing task and wait for its result,
            // preventing the skeleton ↔ empty flicker loop.
        } catch {
            isLoading = false
            ongoingTask = nil
        }
    }

    public func openOffer(_ offer: TyradsOfferModel) async {
        guard !offerOpening else { return }
        offerOpening = true
        loadingCampaignId = offer.campaignId
        defer {
            offerOpening = false
            loadingCampaignId = nil
        }

        // Privacy/onboarding gate before activating, matching Flutter where the
        // Play button runs OnboardingCheck before openOffer.
        guard await Tyrads.instance.checkOnboardingStatus() else { return }

        let result = await openUseCase(offer)
        if result.didActivate {
            reloadAfterOfferActivation = true
            redirectToActivePage = true
        }
        if let url = result.launchURL {
            await UIApplication.shared.open(url)
        }
    }

    /// Force a reload (used by the SDK on language change).
    public func refresh(force: Bool = false) {
        Task { await load(force: force) }
    }
}
