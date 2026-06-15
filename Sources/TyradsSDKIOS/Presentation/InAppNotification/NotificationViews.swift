import SwiftUI

// MARK: - Shared helpers

private func tyradsMainColor() -> Color {
    Color(uiColor: Tyrads.instance.colorMain ?? TyradsSDKConfig.secondaryColor)
}

private func tyradsFormatAmount(_ value: Double) -> String {
    let n = abs(value)
    switch n {
    case 1_000_000...: return String(format: "%.2fM", value / 1_000_000)
    case 1_000...:     return String(format: "%.2fK", value / 1_000)
    default:           return value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

private func tyradsFormatMultiplier(_ value: Double) -> String {
    value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
}

// MARK: - Live countdown (TimelineView)

struct TyradsLiveCountdown: View {
    let seconds: Int
    private let endDate: Date

    init(seconds: Int) {
        self.seconds = seconds
        self.endDate = Date().addingTimeInterval(TimeInterval(max(0, seconds)))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(format(Int(max(0, endDate.timeIntervalSince(context.date)))))
        }
    }

    private func format(_ remaining: Int) -> String {
        if remaining > 86400 {
            return "\(remaining / 86400)d \((remaining % 86400) / 3600)h"
        }
        let h = remaining / 3600, m = (remaining % 3600) / 60, s = remaining % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }
}

// MARK: - Notification card container
// Gradient card (white -> main color, bottom), overhanging icon, close button.

struct TyradsNotificationCardView<Content: View>: View {
    let iconName: String
    let width: CGFloat
    let onClose: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
                .padding(.top, 30)
                .padding(.bottom, 16)
                .frame(width: width)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: tyradsMainColor(), location: 0),
                            .init(color: .white, location: 0.86),
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                .overlay(alignment: .topTrailing) {
                    Button(action: onClose) {
                        Image.tyradsAsset("circle-x")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                }

            Image.tyradsAsset(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 90, height: 90)
                .offset(x: 36, y: -26)
        }
    }
}

// MARK: - Dim backdrop

private struct TyradsNotifBackdrop<Content: View>: View {
    let onTapOutside: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onTapOutside() }
            content()
        }
    }
}

// MARK: - Currency Sales dialog

struct TyradsCurrencySalesNotifView: View {
    let multiplier: Double
    let remainingSeconds: Int
    let onClose: () -> Void

    var body: some View {
        TyradsNotifBackdrop(onTapOutside: onClose) {
            TyradsNotificationCardView(iconName: "coin_stack", width: 328, onClose: onClose) {
                VStack(spacing: 0) {
                    Text("Bonus Rewards\nUnlocked!")
                        .font(TyradsTheme.poppins(16, .bold))
                        .multilineTextAlignment(.center)

                    Divider()
                        .background(Color(red: 224/255, green: 226/255, blue: 231/255))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    (
                        Text("You get \(tyradsFormatMultiplier(multiplier))X bonus rewards!\n")
                            .font(TyradsTheme.poppins(12, .bold))
                        + Text("Go to offerwall and activate new offer!")
                            .font(TyradsTheme.poppins(12, .medium))
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                    HStack(spacing: 0) {
                        Text("Bonus Expires in ")
                            .font(TyradsTheme.poppins(12, .bold))
                            .foregroundColor(.white)
                        TyradsLiveCountdown(seconds: remainingSeconds)
                            .font(TyradsTheme.poppins(12, .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(Color(red: 255/255, green: 85/255, blue: 74/255))
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Button {
                        onClose()
                        Task { try? await Tyrads.instance.showOffers() }
                    } label: {
                        Text("Go to Offerwall")
                            .font(TyradsTheme.poppins(14, .semibold))
                            .foregroundColor(tyradsMainColor())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(tyradsMainColor(), lineWidth: 2)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
    }
}

// MARK: - Limited Time Offer dialog

struct TyradsLimitedTimeOfferNotifView: View {
    let campaigns: [TyradsActiveCampaign]
    let onClose: () -> Void
    @State private var currentIndex = 0

    var body: some View {
        TyradsNotifBackdrop(onTapOutside: onClose) {
            TyradsNotificationCardView(iconName: "coin_timer", width: 328, onClose: onClose) {
                VStack(spacing: 0) {
                    Text("Limited Time Offer")
                        .font(TyradsTheme.poppins(16, .bold))

                    Divider()
                        .background(Color(red: 224/255, green: 226/255, blue: 231/255))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    Text("Limited time offer unlocked! Play now and claim extra rewards!")
                        .font(TyradsTheme.poppins(12, .medium))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    TabView(selection: $currentIndex) {
                        ForEach(Array(campaigns.enumerated()), id: \.element.campaignId) { idx, campaign in
                            TyradsOfferCardView(campaign: campaign)
                                .padding(.horizontal, 8)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 375)
                    .padding(.top, 16)

                    if campaigns.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(campaigns.indices, id: \.self) { idx in
                                Circle()
                                    .fill(idx == currentIndex ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .scaleEffect(idx == currentIndex ? 1.2 : 1.0)
                            }
                        }
                        .padding(.top, 16)
                    }
                }
            }
        }
    }
}

// MARK: - Offer card (inside the limited-time carousel)

struct TyradsOfferCardView: View {
    let campaign: TyradsActiveCampaign

    private var currencyIcon: String { campaign.availableCurrencies.values.first?.currencyIcon ?? "" }
    private var mainColor: Color { tyradsMainColor() }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image.tyradsAsset("alarm_background")
                .resizable()
                .scaledToFit()
                .frame(width: 205, height: 205)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: campaign.app.thumbnail)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 43, height: 43)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(campaign.app.title)
                        .font(TyradsTheme.poppins(12, .semibold))
                        .foregroundColor(Color(red: 30/255, green: 32/255, blue: 32/255))
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(Array(campaign.limitedTimeEvents.enumerated()), id: \.offset) { _, event in
                            taskItem(event)
                        }
                    }
                }
                .frame(height: 190)
                .padding(.top, 16)

                Button {
                    if let url = URL(string: campaign.app.previewUrl) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Play Now")
                        .font(TyradsTheme.poppins(12, .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mainColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.top, 12)
            }
            .padding(16)
        }
        .background(Color(red: 255/255, green: 249/255, blue: 237/255))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func taskItem(_ event: TyradsPayoutEvent) -> some View {
        let vm = TyradsInAppNotificationViewModel.shared
        let showTimer = vm.shouldShowCountdown(event: event)
        let status = vm.getFinalStatusString(event: event)
        let isRejected = event.conversionStatus?.lowercased() == "rejected"
        let payout = event.payoutInfo.values.first?.payoutAmountConverted ?? 0

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(TyradsTheme.poppins(12))
                    .foregroundColor(Color(red: 30/255, green: 32/255, blue: 32/255))

                HStack(spacing: 4) {
                    AsyncImage(url: URL(string: currencyIcon)) { img in
                        img.resizable().scaledToFit()
                    } placeholder: { EmptyView() }
                    .frame(width: 12, height: 12)

                    Text(tyradsFormatAmount(payout))
                        .font(TyradsTheme.poppins(12, .bold))
                        .foregroundColor(mainColor)
                }
            }

            Spacer(minLength: 8)

            if showTimer {
                TyradsLiveCountdown(seconds: Int(event.limitedTimeEventRemainingSeconds))
                    .font(TyradsTheme.poppins(12, .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 22)
                    .background(Color(red: 255/255, green: 85/255, blue: 74/255))
                    .clipShape(Capsule())
            } else {
                Text(status)
                    .font(TyradsTheme.poppins(10, .semibold))
                    .foregroundColor(isRejected
                        ? Color(red: 255/255, green: 85/255, blue: 74/255)
                        : Color(red: 163/255, green: 169/255, blue: 182/255))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
