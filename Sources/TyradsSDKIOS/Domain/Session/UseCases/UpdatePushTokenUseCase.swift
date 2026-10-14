import Foundation

// MARK: - UpdatePushTokenUseCase (Domain)
// Sends a push token that arrived after login already completed, so the
// backend still gets it instead of only whatever (possibly nil) value was
// captured in the original login payload.

struct TyradsUpdatePushTokenUseCase {
    let authRepository: TyradsAuthRepository

    func callAsFunction(token: String) async throws {
        try await authRepository.updateUser(payload: ["devicePushToken": token])
    }
}
