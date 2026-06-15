import Foundation

// MARK: - AuthRepositoryImpl (Data)
// Encrypts the payload when secure mode is on, calls the initialize endpoint,
// and maps the DTO to a domain TyradsLoginResult.

final class TyradsAuthRepositoryImpl: TyradsAuthRepository {
    private let network: TyradsNetworkClient
    private let session: TyradsSessionStore

    init(network: TyradsNetworkClient = TyradsNetworkManager.shared,
         session: TyradsSessionStore = .shared) {
        self.network = network
        self.session = session
    }

    func initialize(payload: [String: Any]) async throws -> TyradsLoginResult {
        let body: [String: Any]
        if session.isSecure, let encryptor = try? TyradsAESEncrypt(encryptionKey: session.encryptionKey) {
            body = try encryptor.encryptAESGCM(payload)
        } else {
            body = payload
        }

        let data = try await network.requestData(
            endpoint: TyradsEndpointNames.initialize,
            method: "POST",
            body: body,
            queryParams: nil
        )

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TyradsInitResponse.self, from: data)

        return TyradsLoginResult(
            token: response.data.token,
            publisherUserId: response.data.accountInfo.publisherUserId,
            newRegisteredUser: response.data.newRegisteredUser,
            mainColorHex: response.data.appInfo.mainColor,
            headerColorHex: response.data.appInfo.headerColor,
            premiumColorHex: response.data.appInfo.premiumColor
        )
    }
}
