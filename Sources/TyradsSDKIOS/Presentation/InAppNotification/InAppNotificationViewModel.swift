import Foundation

// MARK: - InAppNotificationViewModel (Presentation)
// Holds promotion state, loads it via the use case, and exposes the
// shown-tracking + formatting helpers used by the notification views.

@MainActor
final class TyradsInAppNotificationViewModel {
    static let shared = TyradsInAppNotificationViewModel()

    private let loadPromotions: TyradsLoadInAppPromotionsUseCase
    private let shownStore: TyradsNotificationShownStore

    private(set) var activeOffers: [TyradsActiveCampaign] = []
    private(set) var currencySales: TyradsCurrencySales?
    private(set) var currencySaleMultiplier: Double?
    private(set) var currencySaleRemainingSeconds: Int = 0

    init(repository: TyradsInAppNotificationRepository = TyradsInAppNotificationRepositoryImpl(),
         shownStore: TyradsNotificationShownStore = TyradsNotificationShownStore()) {
        self.loadPromotions = TyradsLoadInAppPromotionsUseCase(repository: repository)
        self.shownStore = shownStore
    }

    func initialize() async {
        let promotions = await loadPromotions()
        activeOffers = promotions.activeOffers
        currencySales = promotions.currencySales
        currencySaleMultiplier = promotions.currencySaleMultiplier
        currencySaleRemainingSeconds = promotions.currencySaleRemainingSeconds
    }

    func clear() {
        activeOffers.removeAll()
        currencySales = nil
    }

    // MARK: Shown tracking (delegated to store)

    func hasShownCurrencySalesNotification(saleId: String) -> Bool {
        shownStore.hasShownCurrencySales(saleId: saleId)
    }
    func markCurrencySalesNotificationAsShown(saleId: String) {
        shownStore.markCurrencySalesShown(saleId: saleId)
    }
    func hasShownLimitedTimeOfferNotification(campaignIds: [Int]) -> Bool {
        shownStore.hasShownLimitedTimeOffer(campaignIds: campaignIds)
    }
    func markLimitedTimeOfferNotificationAsShown(campaignIds: [Int]) {
        shownStore.markLimitedTimeOfferShown(campaignIds: campaignIds)
    }

    // MARK: Display helpers

    func shouldShowCountdown(event: TyradsPayoutEvent) -> Bool {
        let isDailyLimitIncomplete = event.dailyCount == 0
            || (event.dailyLimit ?? 0) == 0
            || event.dailyCount < (event.dailyLimit ?? 0)

        if !event.allowDuplicateEvents {
            return event.conversionStatus == nil
        }
        return isDailyLimitIncomplete
    }

    func getFinalStatusString(event: TyradsPayoutEvent) -> String {
        if !event.allowDuplicateEvents {
            if event.conversionStatus == "approved" { return "Completed" }
            if event.conversionStatus == "rejected" { return "Rejected" }
        }
        let isDailyLimitComplete = event.dailyCount != 0
            && (event.dailyLimit ?? 0) != 0
            && event.dailyCount == (event.dailyLimit ?? 0)
        if event.allowDuplicateEvents && isDailyLimitComplete { return "Completed" }
        return ""
    }

    func formatTimer(remainingSeconds: Double?) -> String {
        guard let seconds = remainingSeconds, seconds > 0 else { return "" }
        let days = Int(seconds / 86400)
        let hours = Int(seconds.truncatingRemainder(dividingBy: 86400) / 3600)
        let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600) / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))

        func pad(_ v: Int) -> String { String(format: "%02d", v) }

        if days > 0 { return "\(pad(days))d \(pad(hours))h" }
        return "\(pad(hours)):\(pad(minutes)):\(pad(secs))"
    }
}
