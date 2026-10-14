import Foundation

// MARK: - Device info boundary (Domain)
// Abstracts platform device/network introspection so use cases stay testable.

protocol TyradsDeviceInfoProviding {
    func deviceDetails() async -> [String: Any]
}
