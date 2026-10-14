import Foundation

// MARK: - NotificationShownStore (Data / Local)
// Persists which promotions were already shown today, keyed per user.

final class TyradsNotificationShownStore {
    private let defaults = UserDefaults.standard
    private let session: TyradsSessionStore

    init(session: TyradsSessionStore = .shared) {
        self.session = session
    }

    private var today: String {
        String(ISO8601DateFormatter().string(from: Date()).prefix(10))
    }

    private func key(_ base: String) -> String {
        "\(base)\(session.publisherUserID)"
    }

    private func map(forKey key: String) -> [String: String] {
        guard let data = defaults.string(forKey: key),
              let json = try? JSONSerialization.jsonObject(with: Data(data.utf8)) as? [String: String] else {
            return [:]
        }
        return json
    }

    private func save(_ json: [String: String], forKey key: String) {
        if let encoded = try? JSONSerialization.data(withJSONObject: json),
           let str = String(data: encoded, encoding: .utf8) {
            defaults.set(str, forKey: key)
        }
    }

    // MARK: Currency sales

    func hasShownCurrencySales(saleId: String) -> Bool {
        guard !saleId.isEmpty else { return false }
        return map(forKey: key(TyradsKeyNames.hasShownCurrencySalesNotification))[saleId] == today
    }

    func markCurrencySalesShown(saleId: String) {
        guard !saleId.isEmpty else { return }
        let k = key(TyradsKeyNames.hasShownCurrencySalesNotification)
        var json = map(forKey: k)
        json[saleId] = today
        save(json, forKey: k)
    }

    // MARK: Limited time offers

    func hasShownLimitedTimeOffer(campaignIds: [Int]) -> Bool {
        guard !campaignIds.isEmpty else { return false }
        let json = map(forKey: key(TyradsKeyNames.hasShownLimitedTimeOfferNotification))
        return campaignIds.allSatisfy { json[String($0)] == today }
    }

    func markLimitedTimeOfferShown(campaignIds: [Int]) {
        guard !campaignIds.isEmpty else { return }
        let k = key(TyradsKeyNames.hasShownLimitedTimeOfferNotification)
        var json = map(forKey: k)
        campaignIds.forEach { json[String($0)] = today }
        save(json, forKey: k)
    }
}
