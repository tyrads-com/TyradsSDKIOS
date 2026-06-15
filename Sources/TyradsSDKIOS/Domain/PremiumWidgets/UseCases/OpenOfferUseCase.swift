import Foundation

// MARK: - Offer event sink (Domain boundary)
// Lets the use case emit tracking/callbacks without depending on the SDK facade.

protocol TyradsOfferEventSink {
    func track(_ activity: String)
    func notifyCampaignActivated(_ payload: [String: Any])
}

// MARK: - OpenOfferUseCase (Domain)
// Decides what URL to launch for an offer and performs the activation
// side effects (track, activate, callback, s2s ping). URL launching itself
// is a platform concern handled by the presentation layer.

struct TyradsOpenOfferResult {
    let launchURL: URL?
    let didActivate: Bool
}

struct TyradsOpenOfferUseCase {
    let repository: TyradsOffersRepository
    let events: TyradsOfferEventSink

    func callAsFunction(_ offer: TyradsOfferModel) async -> TyradsOpenOfferResult {
        let clickUrl = offer.tracking.clickUrl ?? ""
        let s2sClickUrl = offer.tracking.s2sClickUrl

        var urlString = clickUrl
        var didActivate = false

        if offer.validity.isInstalled {
            urlString = offer.app.previewUrl
        } else {
            events.track(offer.validity.isRetryDownload
                ? TyradsActivity.campaignActivatedRetry
                : TyradsActivity.campaignActivated)

            try? await repository.activateOffer(id: offer.campaignId)
            didActivate = true

            events.notifyCampaignActivated([
                "campaignId": offer.campaignId,
                "campaignName": offer.campaignName,
                "appId": offer.app.id,
                "appName": offer.app.title,
                "appCategory": offer.app.storeCategory,
                "clickUrl": clickUrl,
                "s2sClickUrl": s2sClickUrl as Any
            ])
        }

        if let s2s = s2sClickUrl, let s2sURL = URL(string: s2s) {
            await repository.pingS2S(url: s2sURL)
        }

        return TyradsOpenOfferResult(launchURL: URL(string: urlString), didActivate: didActivate)
    }
}
