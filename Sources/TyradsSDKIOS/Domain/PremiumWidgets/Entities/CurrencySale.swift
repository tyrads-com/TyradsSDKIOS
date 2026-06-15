import Foundation

// MARK: - Currency sale entity (Domain)

public struct TyradsCurrencySales: Codable {
    public let name: String?
    public let multiplier: Double?
    public let bannerUrl: String?
    public let dateStart: String?
    public let dateEnd: String?
    public let remainingTimeSeconds: Int?
}
