import Foundation

// MARK: - TrackingRepositoryImpl (Data)

final class TyradsTrackingRepositoryImpl: TyradsTrackingRepository {
    private let network: TyradsNetworkClient
    private let session: TyradsSessionStore

    init(network: TyradsNetworkClient = TyradsNetworkManager.shared,
         session: TyradsSessionStore = .shared) {
        self.network = network
        self.session = session
    }

    func trackActivity(_ activity: String) async throws {
        var body: [String: Any] = ["activity": activity]
        if session.isSecure, let encryptor = try? TyradsAESEncrypt(encryptionKey: session.encryptionKey) {
            body = try encryptor.encryptAESGCM(body)
        }
        _ = try await network.requestData(
            endpoint: TyradsEndpointNames.userActivities,
            method: "POST",
            body: body,
            queryParams: nil
        )
    }
}
