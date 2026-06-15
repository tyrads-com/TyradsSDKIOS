import SwiftUI

private struct TyradsTopRoundedShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

public enum TyradsPremiumWidgetStyle {
    case list
    case sliderCards
}

// MARK: - Helpers

/// Compact number formatting, equivalent to Flutter's `numeral(digits: 2)`.
private func tyradsCompactNumber(_ value: Double) -> String {
    let n = abs(value)
    switch n {
    case 1_000_000...: return String(format: "%.2fM", value / 1_000_000)
    case 1_000...:     return String(format: "%.2fK", value / 1_000)
    default:           return value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

private func tyradsPremiumColor() -> Color {
    Color(uiColor: Tyrads.instance.colorPremium ?? TyradsSDKConfig.secondaryColor)
}

/// Open the offer's detail page inside the offerwall web view (matches Flutter:
/// tapping a card routes to the offer detail, it does NOT activate the campaign).
private func tyradsOpenOfferDetail(_ offer: TyradsOfferModel) {
    Task { try? await Tyrads.instance.showOffers(campaignID: offer.campaignId, route: TyradsDeepRoutes.offers) }
}

/// Folded-corner triangle behind the bonus pill (Flutter's TrianglePainter).
private struct TyradsCornerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Main Widget

/// Drop-in SwiftUI widget showing top offers. Embed in your view hierarchy.
/// Usage: Tyrads.instance.topOffersWidget() or TyradsPremiumOffersView()
public struct TyradsPremiumOffersView: View {
    @ObservedObject private var viewModel = TyradsPremiumWidgetsViewModel.shared

    private let widgetStyle: TyradsPremiumWidgetStyle

    public init(widgetStyle: TyradsPremiumWidgetStyle = .list) {
        self.widgetStyle = widgetStyle
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.offers.isEmpty {
                TyradsPremiumLoadingView(widgetStyle: widgetStyle)
            } else if viewModel.offers.isEmpty {
                TyradsPremiumEmptyView()
            } else {
                TyradsPremiumCardContainer(viewModel: viewModel, widgetStyle: widgetStyle)
            }
        }
        .task { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await viewModel.load(force: true) }
        }
    }
}

// MARK: - Card Container (full widget with header + content + footer)

struct TyradsPremiumCardContainer: View {
    @ObservedObject var viewModel: TyradsPremiumWidgetsViewModel
    let widgetStyle: TyradsPremiumWidgetStyle

    private var premiumColor: Color { tyradsPremiumColor() }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image.tyradsTemplate("diamond")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 12)
                    .foregroundColor(premiumColor)

                Text(TyradsLocalizationService.shared.localizedString("data.widget.page.title"))
                    .font(TyradsTheme.poppins(14, .semibold))
                    .foregroundColor(premiumColor)

                Spacer()

                Button {
                    Task { try? await Tyrads.instance.showOffers() }
                } label: {
                    HStack(spacing: 4) {
                        Text(TyradsLocalizationService.shared.localizedString("data.widget.button.moreOffers"))
                            .font(TyradsTheme.poppins(13, .semibold))
                            .foregroundColor(premiumColor)
                        Image.tyradsTemplate("angle_up")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12)
                            .foregroundColor(premiumColor)
                            .rotationEffect(.degrees(90))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            if widgetStyle == .list {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.offers.enumerated()), id: \.element.campaignId) { idx, offer in
                        TyradsOfferListItemView(
                            viewModel: viewModel,
                            offer: offer,
                            index: idx,
                            currencySales: viewModel.currencySales
                        )
                        if idx < viewModel.offers.count - 1 {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 16)
            } else {
                TyradsPremiumSliderView(viewModel: viewModel)
                    .padding(.top, 8)
            }

            // Active offers footer button
            if viewModel.activatedCount > 0 {
                Button {
                    Task { try? await Tyrads.instance.showOffers(route: TyradsDeepRoutes.activeOffers) }
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("\(viewModel.activatedCount) Active Offer\(viewModel.activatedCount > 1 ? "s" : "") — Continue Playing")
                            .font(TyradsTheme.poppins(13, .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(premiumColor)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Empty State

struct TyradsPremiumEmptyView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text(TyradsLocalizationService.shared.localizedString("data.widget.empty.noOffers"))
                .multilineTextAlignment(.center)
                .font(TyradsTheme.poppins(14, .semibold))
                .foregroundColor(.white)

            Button {
                Task { try? await Tyrads.instance.showOffers(route: TyradsDeepRoutes.activeOffers) }
            } label: {
                Text(TyradsLocalizationService.shared.localizedString("data.widget.button.continuePlaying"))
                    .font(TyradsTheme.poppins(12, .semibold))
                    .foregroundColor(tyradsPremiumColor())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            Image.tyradsAsset("premium-emptybg")
                .resizable()
                .scaledToFill()
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - List Item
// Row tap -> offer detail. Trailing "Play" button -> activate + launch.

struct TyradsOfferListItemView: View {
    @ObservedObject var viewModel: TyradsPremiumWidgetsViewModel
    let offer: TyradsOfferModel
    let index: Int
    let currencySales: TyradsCurrencySales?

    private var premiumColor: Color { tyradsPremiumColor() }
    private var isLoading: Bool { viewModel.loadingCampaignId == offer.campaignId }
    private var anyLoading: Bool { viewModel.loadingCampaignId != nil }
    private var basePayout: Double { offer.payoutSummary.values.first?.totalPlayablePayoutConverted ?? 0 }
    private var multiplier: Double { currencySales?.multiplier ?? 1 }
    private var currencyIcon: String? { offer.availableCurrencies.values.first?.currencyIcon }

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with rank medal
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: offer.app.thumbnail)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if index < 5 {
                    Image.tyradsAsset("rank_\(index + 1)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .offset(x: -8, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if currencySales != nil {
                    Text("\(tyradsCompactNumber(multiplier))x BONUS")
                        .font(TyradsTheme.poppins(10, .bold))
                        .foregroundColor(premiumColor)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(premiumColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text(offer.app.title)
                    .font(TyradsTheme.poppins(12))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if currencySales != nil {
                        Text(tyradsCompactNumber(basePayout))
                            .font(TyradsTheme.poppins(12, .light))
                            .strikethrough()
                            .foregroundColor(Color(.darkGray))
                    }
                    if let icon = currencyIcon {
                        AsyncImage(url: URL(string: icon)) { img in
                            img.resizable().scaledToFit()
                        } placeholder: { EmptyView() }
                        .frame(width: 14, height: 14)
                    }
                    Text(tyradsCompactNumber(basePayout * multiplier))
                        .font(TyradsTheme.poppins(12, .bold))
                }
            }

            Spacer()

            // Play button -> activate + launch
            Button {
                Task { await viewModel.openOffer(offer) }
            } label: {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                            .tint(Color(.systemGray))
                    }
                    Text(TyradsLocalizationService.shared.localizedString("data.widget.button.play"))
                        .font(TyradsTheme.poppins(13, .semibold))
                        .foregroundColor(anyLoading ? Color(.systemGray) : Color(uiColor: Tyrads.instance.colorPremiumFg ?? .white))
                }
                .frame(minWidth: 75)
                .frame(height: 42)
                .padding(.horizontal, 12)
                .background(anyLoading ? Color(.systemGray5) : premiumColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(anyLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !anyLoading else { return }
            tyradsOpenOfferDetail(offer)
        }
    }
}

// MARK: - Slider Cards

struct TyradsPremiumSliderView: View {
    @ObservedObject var viewModel: TyradsPremiumWidgetsViewModel
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentIndex) {
                ForEach(Array(viewModel.offers.enumerated()), id: \.element.campaignId) { idx, offer in
                    TyradsOfferSlideCardView(
                        viewModel: viewModel,
                        offer: offer,
                        currencySales: viewModel.currencySales
                    )
                    .tag(idx)
                    .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 260)

            HStack(spacing: 6) {
                ForEach(viewModel.offers.indices, id: \.self) { idx in
                    Circle()
                        .fill(idx == currentIndex
                              ? tyradsPremiumColor()
                              : tyradsPremiumColor().opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// Full creative card: image + info card with Play Now button.
// Card / info-icon tap -> offer detail. "Play Now" button -> activate + launch.
struct TyradsOfferSlideCardView: View {
    @ObservedObject var viewModel: TyradsPremiumWidgetsViewModel
    let offer: TyradsOfferModel
    let currencySales: TyradsCurrencySales?

    private var premiumColor: Color { tyradsPremiumColor() }
    private var isLoading: Bool { viewModel.loadingCampaignId == offer.campaignId }
    private var basePayout: Double { offer.payoutSummary.values.first?.totalPlayablePayoutConverted ?? 0 }
    private var multiplier: Double { currencySales?.multiplier ?? 1 }
    private var currencyIcon: String? { offer.availableCurrencies.values.first?.currencyIcon }
    private var creativeURL: String {
        offer.creative.creativePacks.first?.creatives.first?.fileUrl ?? offer.creative.creativeUrl
    }

    // Currency-sale bonus tag: folded triangle behind a pill, matching Flutter.
    private var bonusPill: some View {
        ZStack(alignment: .topLeading) {
            TyradsCornerTriangle()
                .fill(premiumColor)
                .brightness(-0.15)
                .frame(width: 12, height: 22)
                .offset(x: 8, y: 30)

            Text("\(tyradsCompactNumber(multiplier))x BONUS")
                .font(TyradsTheme.poppins(12, .bold))
                .foregroundColor(Color(uiColor: Tyrads.instance.colorPremiumFg ?? .white))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(premiumColor)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 4)
                .offset(x: 8, y: 8)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Creative banner
            AsyncImage(url: URL(string: creativeURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .mask(TyradsTopRoundedShape(radius: 16))
            .overlay(alignment: .topTrailing) {
                if offer.campaignPremium {
                    Image.tyradsTemplate("diamond")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(red: 30/255, green: 32/255, blue: 32/255).opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(16)
                }
            }
            .overlay(alignment: .topLeading) {
                if currencySales != nil { bonusPill }
            }

            // Info card
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    AsyncImage(url: URL(string: offer.app.thumbnail)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(offer.app.title)
                        .font(TyradsTheme.poppins(14))
                        .lineLimit(2)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        if currencySales != nil {
                            Text(tyradsCompactNumber(basePayout))
                                .font(TyradsTheme.poppins(12, .light))
                                .strikethrough()
                                .foregroundColor(Color(.darkGray))
                        }
                        HStack(spacing: 4) {
                            if let icon = currencyIcon {
                                AsyncImage(url: URL(string: icon)) { img in
                                    img.resizable().scaledToFit()
                                } placeholder: { EmptyView() }
                                .frame(width: 16, height: 16)
                            }
                            Text(tyradsCompactNumber(basePayout * multiplier))
                                .font(TyradsTheme.poppins(14, .bold))
                        }
                    }

                    Button {
                        tyradsOpenOfferDetail(offer)
                    } label: {
                        Image.tyradsAsset("info_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                }

                // Play Now -> activate + launch
                Button {
                    Task { await viewModel.openOffer(offer) }
                } label: {
                    HStack(spacing: 6) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.7)
                                .tint(Color(.systemGray))
                        }
                        Text(TyradsLocalizationService.shared.localizedString("data.shared.cta.playNow"))
                            .font(TyradsTheme.poppins(14, .semibold))
                            .foregroundColor(isLoading ? Color(.systemGray) : Color(uiColor: Tyrads.instance.colorPremiumFg ?? .white))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(isLoading ? Color(.systemGray5) : premiumColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }
            .padding(12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isLoading else { return }
            tyradsOpenOfferDetail(offer)
        }
    }
}

// MARK: - Loading Skeleton

struct TyradsPremiumLoadingView: View {
    let widgetStyle: TyradsPremiumWidgetStyle
    @State private var animating = false

    init(widgetStyle: TyradsPremiumWidgetStyle = .list) {
        self.widgetStyle = widgetStyle
    }

    var body: some View {
        if widgetStyle == .list {
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(animating ? 0.1 : 0.25))
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(animating ? 0.1 : 0.25))
                                .frame(height: 12)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(animating ? 0.1 : 0.25))
                                .frame(width: 80, height: 10)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onAppear { animating = true }
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animating)
        } else {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(animating ? 0.1 : 0.25))
                        .frame(width: 100, height: 90)
                }
            }
            .padding()
            .onAppear { animating = true }
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animating)
        }
    }
}

// MARK: - UIKit bridge

public final class TyradsPremiumOffersViewController: UIViewController {
    private let widgetStyle: TyradsPremiumWidgetStyle

    public init(widgetStyle: TyradsPremiumWidgetStyle = .list) {
        self.widgetStyle = widgetStyle
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let hosting = UIHostingController(rootView: TyradsPremiumOffersView(widgetStyle: widgetStyle))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        hosting.view.backgroundColor = .clear
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - Previews

#Preview("List Style") {
    TyradsPremiumOffersView(widgetStyle: .list)
        .padding()
}

#Preview("Slider Cards") {
    TyradsPremiumOffersView(widgetStyle: .sliderCards)
        .padding()
}

#Preview("Empty State") {
    TyradsPremiumEmptyView()
        .padding()
}

#Preview("Loading") {
    TyradsPremiumLoadingView(widgetStyle: .list)
        .padding()
}
