import Foundation

// MARK: - Tracking boundary (Domain)

protocol TyradsTrackingRepository {
    func trackActivity(_ activity: String) async throws
}
