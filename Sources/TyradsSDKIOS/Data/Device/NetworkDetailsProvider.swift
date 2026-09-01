import Foundation
import SystemConfiguration

final class TyradsNetworkDetailsProvider {
    func getNetworkDetails() async -> [String: Any] {
        var details: [String: Any] = [:]
        details["connectionType"] = getConnectionType()
        return details
    }

    private func getConnectionType() -> String {
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "api.tyrads.com") else {
            return "Unknown"
        }
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)

        guard flags.contains(.reachable) else { return "No Connection" }

        if flags.contains(.isWWAN) {
            return "Mobile Data"
        }
        return "WiFi"
    }

}
