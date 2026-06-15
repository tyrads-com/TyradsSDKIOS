import Foundation
import Network
import SystemConfiguration

final class TyradsNetworkDetailsProvider {
    func getNetworkDetails() async -> [String: Any] {
        var details: [String: Any] = [:]
        details["connectionType"] = getConnectionType()
        details["networkSpeed"] = await measureNetworkSpeed()
        details["isVpnActive"] = isVPNActive()
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

    private func isVPNActive() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings() else { return false }
        let nsDict = cfDict.takeRetainedValue() as NSDictionary
        guard let keys = nsDict["__SCOPED__"] as? NSDictionary else { return false }
        for key in keys.allKeys {
            if let keyStr = key as? String,
               (keyStr.hasPrefix("tap") || keyStr.hasPrefix("tun") || keyStr.hasPrefix("ppp") || keyStr.hasPrefix("ipsec")) {
                return true
            }
        }
        return false
    }

    private func measureNetworkSpeed() async -> String {
        guard let url = URL(string: "https://www.google.com") else { return "0.00 KB/s" }
        let start = Date()
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let elapsed = Date().timeIntervalSince(start)
            let bytesPerSec = Double(data.count) / elapsed
            if bytesPerSec >= 1_073_741_824 {
                return String(format: "%.2f GB/s", bytesPerSec / 1_073_741_824)
            } else if bytesPerSec >= 1_048_576 {
                return String(format: "%.2f MB/s", bytesPerSec / 1_048_576)
            } else {
                return String(format: "%.2f KB/s", bytesPerSec / 1024)
            }
        } catch {
            return "0.00 KB/s"
        }
    }
}
