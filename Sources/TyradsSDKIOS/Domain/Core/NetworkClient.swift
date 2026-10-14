import Foundation

// MARK: - NetworkClient boundary (Domain)
// Transport abstraction so repositories depend on an interface, not a concrete
// URLSession-backed manager. Implemented in the Data layer.

protocol TyradsNetworkClient: Sendable {
    func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]?,
        queryParams: [String: String]?
    ) async throws -> T

    func requestData(
        endpoint: String,
        method: String,
        body: [String: Any]?,
        queryParams: [String: String]?
    ) async throws -> Data
}
