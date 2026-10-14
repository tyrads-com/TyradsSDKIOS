import Foundation

// MARK: - Advertising id boundary (Domain)

public struct TyradsAdvertisingIdentifier {
    public let identifierType: String  // "IDFA" or "OTHER"
    public let identifier: String
}

protocol TyradsAdvertisingIdProviding {
    /// Resolves the advertising identifier, requesting ATT authorization where
    /// available. Falls back to `fallbackId` when IDFA is unavailable.
    func resolve(fallbackId: String) async -> TyradsAdvertisingIdentifier
}
