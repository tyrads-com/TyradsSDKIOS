import Foundation

// MARK: - Auth boundary (Domain)

public struct TyradsLoginResult {
    public let token: String
    public let publisherUserId: String
    public let newRegisteredUser: Bool
    public let mainColorHex: String
    public let headerColorHex: String
    public let premiumColorHex: String
}

protocol TyradsAuthRepository {
    /// Performs the backend initialize/login call with an already-built payload.
    func initialize(payload: [String: Any]) async throws -> TyradsLoginResult

    /// Updates a field on the already-logged-in user (e.g. a push token that
    /// arrived after login already completed).
    func updateUser(payload: [String: Any]) async throws
}
