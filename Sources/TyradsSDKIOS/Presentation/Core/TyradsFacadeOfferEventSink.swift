import Foundation

// MARK: - Event sink adapter (Presentation)
// Bridges the Domain's TyradsOfferEventSink to the public SDK facade so the
// use case stays free of any dependency on Tyrads.instance.

struct TyradsFacadeOfferEventSink: TyradsOfferEventSink {
    func track(_ activity: String) {
        Tyrads.instance.track(activity)
    }

    func notifyCampaignActivated(_ payload: [String: Any]) {
        Tyrads.instance.triggerCallback(.campaignActivated, payload)
    }
}
