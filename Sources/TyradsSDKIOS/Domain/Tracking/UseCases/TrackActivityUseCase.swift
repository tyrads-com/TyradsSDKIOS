import Foundation

// MARK: - TrackActivityUseCase (Domain)

struct TyradsTrackActivityUseCase {
    let repository: TyradsTrackingRepository

    func callAsFunction(_ activity: String) async throws {
        try await repository.trackActivity(activity)
    }
}
