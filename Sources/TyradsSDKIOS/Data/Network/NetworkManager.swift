import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case unknown(Error)
}

final class TyradsNetworkManager: TyradsNetworkClient, @unchecked Sendable {
    static let shared = TyradsNetworkManager()

    private let session: URLSession
    private let baseURL: URL

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 100
        config.timeoutIntervalForResource = 300
        config.httpMaximumConnectionsPerHost = 4
        session = URLSession(configuration: config)
        baseURL = URL(string: TyradsSDKConfig.baseURL)!
    }

    // MARK: - Generic request

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> T {
        let data = try await requestData(endpoint: endpoint, method: method, body: body, queryParams: queryParams)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func requestData(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> Data {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false)!
        if let queryParams {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = urlComponents.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        addHeaders(to: &request, endpoint: endpoint)

        if let body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
//        print("\n🚀 ===== TYRADS REQUEST =====")
//        print("URL: \(url.absoluteString)")
//        print("Method: \(method)")
//
//        if let headers = request.allHTTPHeaderFields {
//            print("Headers:")
//            headers.forEach { key, value in
//                print("  \(key): \(value)")
//            }
//        }
//
//        if let bodyData = request.httpBody,
//           let bodyString = String(data: bodyData, encoding: .utf8) {
//            print("Body:")
//            print(bodyString)
//        }
//
//        print("============================\n")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
//            print("===================================")
//                print("URL: \(url.absoluteString)")
//                print("Status Code: \(httpResponse.statusCode)")
//
//                if let bodyString = String(data: data, encoding: .utf8) {
//                    print("Response:")
//                    print(bodyString)
//                }
//
//                print("===================================")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return data
    }

    private func addHeaders(to request: inout URLRequest, endpoint: String) {
        let session = TyradsSessionStore.shared
        let isInitEndpoint = endpoint == TyradsEndpointNames.initialize || endpoint.contains("translations")

        if !isInitEndpoint, let userId = session.storedUserId {
            request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        }
        request.setValue(session.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(session.apiSecret, forHTTPHeaderField: "X-API-Secret")
        request.setValue(TyradsSDKConfig.sdkPlatform, forHTTPHeaderField: "X-SDK-Platform")
        request.setValue(TyradsSDKConfig.sdkVersion, forHTTPHeaderField: "X-SDK-Version")
        request.setValue(
            session.isSecure ? "BASIC" : "PLAIN",
            forHTTPHeaderField: "X-Secure-Mode"
        )
    }
}
