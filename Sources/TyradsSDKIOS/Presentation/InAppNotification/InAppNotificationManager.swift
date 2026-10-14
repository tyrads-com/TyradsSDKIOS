import UIKit
import SwiftUI

// MARK: - Promo dismissal notifying

protocol TyradsPromoDismissNotifying: AnyObject {
    var onDismiss: (() -> Void)? { get set }
}

// MARK: - InAppNotificationManager (Presentation)
// Mirrors the Flutter SDK: build an ordered promo queue (limited-time offer
// first, then currency sale), then present each dialog sequentially — waiting
// for dismissal and marking it shown before moving on. Retries until a
// presenter is available (the Flutter context bridge behaviour).

@MainActor
final class TyradsInAppNotificationManager {
    static let shared = TyradsInAppNotificationManager()
    private init() {}

    private let viewModel = TyradsInAppNotificationViewModel.shared
    private var isShowing = false

    private enum PromoAction {
        case limitedTimeOffer(campaigns: [TyradsActiveCampaign], campaignIds: [Int], delayAfter: TimeInterval)
        case currencySale(sales: TyradsCurrencySales, saleId: String, delayAfter: TimeInterval)
    }

    func evaluatePromotions() {
        Task { @MainActor in
            await execute(buildQueue())
        }
    }

    @MainActor
    private func buildQueue() -> [PromoAction] {
        var queue: [PromoAction] = []

        if !viewModel.activeOffers.isEmpty {
            let campaignIds = viewModel.activeOffers.map { $0.campaignId }
            if !viewModel.hasShownLimitedTimeOfferNotification(campaignIds: campaignIds) {
                queue.append(.limitedTimeOffer(
                    campaigns: viewModel.activeOffers,
                    campaignIds: campaignIds,
                    delayAfter: 0.3
                ))
            }
        }

        if let sales = viewModel.currencySales {
            let saleId = sales.name ?? "default_sale"
            if !viewModel.hasShownCurrencySalesNotification(saleId: saleId) {
                queue.append(.currencySale(sales: sales, saleId: saleId, delayAfter: 0))
            }
        }

        return queue
    }

    @MainActor
    private func execute(_ actions: [PromoAction]) async {
        guard !isShowing, !actions.isEmpty else { return }
        isShowing = true
        defer { isShowing = false }

        guard await waitForPresenter() != nil else { return }
        try? await Task.sleep(nanoseconds: 500_000_000) // settle, matches bridge delay

        for action in actions {
            switch action {
            case let .limitedTimeOffer(campaigns, campaignIds, delayAfter):
                if !viewModel.hasShownLimitedTimeOfferNotification(campaignIds: campaignIds),
                   let presenter = topViewController() {
                    await presentAndWait(
                        TyradsLimitedTimeOfferNotifViewController(campaigns: campaigns),
                        from: presenter
                    )
                    viewModel.markLimitedTimeOfferNotificationAsShown(campaignIds: campaignIds)
                }
                await sleep(delayAfter)

            case let .currencySale(sales, saleId, delayAfter):
                if !viewModel.hasShownCurrencySalesNotification(saleId: saleId),
                   let presenter = topViewController() {
                    let multiplier = viewModel.currencySaleMultiplier ?? sales.multiplier ?? 1
                    await presentAndWait(
                        TyradsCurrencySalesNotifViewController(
                            multiplier: multiplier,
                            remainingSeconds: viewModel.currencySaleRemainingSeconds
                        ),
                        from: presenter
                    )
                    viewModel.markCurrencySalesNotificationAsShown(saleId: saleId)
                }
                await sleep(delayAfter)
            }
        }
    }

    /// Retry until a presenter is available (~1.5s), mirroring the context bridge.
    @MainActor
    private func waitForPresenter() async -> UIViewController? {
        for _ in 0..<10 {
            if let vc = topViewController() { return vc }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        return topViewController()
    }

    @MainActor
    private func presentAndWait(_ vc: UIViewController & TyradsPromoDismissNotifying, from presenter: UIViewController) async {
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            vc.onDismiss = { continuation.resume() }
            presenter.present(vc, animated: true)
        }
    }

    private func sleep(_ seconds: TimeInterval) async {
        guard seconds > 0 else { return }
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        return findTop(root)
    }

    private func findTop(_ vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController { return findTop(presented) }
        if let nav = vc as? UINavigationController { return findTop(nav.visibleViewController ?? nav) }
        if let tab = vc as? UITabBarController { return findTop(tab.selectedViewController ?? tab) }
        return vc
    }
}

// MARK: - Hosting helper

private extension UIViewController {
    func embedNotifContent<V: View>(_ rootView: V) {
        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
    }
}

// MARK: - Currency Sales Notification VC (hosts SwiftUI)

final class TyradsCurrencySalesNotifViewController: UIViewController, TyradsPromoDismissNotifying {
    var onDismiss: (() -> Void)?
    private let multiplier: Double
    private let remainingSeconds: Int

    init(multiplier: Double, remainingSeconds: Int) {
        self.multiplier = multiplier
        self.remainingSeconds = remainingSeconds
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
        onDismiss = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        embedNotifContent(
            TyradsCurrencySalesNotifView(
                multiplier: multiplier,
                remainingSeconds: remainingSeconds,
                onClose: { [weak self] in self?.dismiss(animated: true) }
            )
        )
    }
}

// MARK: - Limited Time Offer Notification VC (hosts SwiftUI)

final class TyradsLimitedTimeOfferNotifViewController: UIViewController, TyradsPromoDismissNotifying {
    var onDismiss: (() -> Void)?
    private let campaigns: [TyradsActiveCampaign]

    init(campaigns: [TyradsActiveCampaign]) {
        self.campaigns = campaigns
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onDismiss?()
        onDismiss = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        embedNotifContent(
            TyradsLimitedTimeOfferNotifView(
                campaigns: campaigns,
                onClose: { [weak self] in self?.dismiss(animated: true) }
            )
        )
    }
}
