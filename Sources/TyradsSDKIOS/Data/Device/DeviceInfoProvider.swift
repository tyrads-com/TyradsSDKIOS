import UIKit
import Foundation

final class TyradsDeviceInfoProvider: TyradsDeviceInfoProviding {
    private let networkController = TyradsNetworkDetailsProvider()

    func deviceDetails() async -> [String: Any] {
        var fd: [String: Any] = [:]
        let prefs = UserDefaults.standard
        let device = UIDevice.current
        let networkDetails = await networkController.getNetworkDetails()

        // Device identifiers
        fd["deviceId"] = device.identifierForVendor?.uuidString ?? ""
        fd["device"] = device.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        fd["deviceName"] = device.name
        fd["brand"] = "Apple"
        fd["model"] = getModelIdentifier()
        fd["modelName"] = device.model
        fd["hardware"] = getModelIdentifier()
        fd["product"] = "Darwin"
        fd["baseOs"] = device.systemName
        fd["releaseVersion"] = device.systemVersion

        // App info
        let appBundle = Bundle.main
        fd["build"] = appBundle.infoDictionary?["CFBundleVersion"] as? String ?? ""
        fd["version"] = appBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        fd["package"] = appBundle.bundleIdentifier ?? ""
        fd["apiVersion"] = TyradsSDKConfig.apiVersion
        fd["platform"] = "iOS"
        fd["installerStore"] = "App Store"
        fd["osLang"] = Locale.current.languageCode ?? "en"

        // Security
        fd["rooted"] = isJailbroken()
        fd["virtual"] = isSimulator()

        // Network
        fd["connectionType"] = networkDetails["connectionType"] ?? "Unknown"
        fd["isVpnActive"] = networkDetails["isVpnActive"] ?? false

        // SDK info
        fd["sdkVersion"] = TyradsSDKConfig.sdkVersion
        fd["sdkPlatform"] = TyradsSDKConfig.sdkPlatform

        // Memory
        fd["totalMemory"] = getTotalDiskSpace()

        // Time
        fd["timeZone"] = TimeZone.current.identifier
        fd["timeZoneOffset"] = TimeZone.current.secondsFromGMT()
        fd["systemTime"] = String(Int64(Date().timeIntervalSince1970 * 1000))

        // Screen
        let screen = UIScreen.main
        fd["screenWidth"] = Int(screen.bounds.width * screen.scale)
        fd["screenHeight"] = Int(screen.bounds.height * screen.scale)
        fd["screenDensity"] = screen.scale

        // Placeholder interaction metrics (iOS does not expose these natively)
        fd["keyboardNumEvents"] = 0
        fd["keyboardScore"] = 0
        fd["clipboardNumEvents"] = 0
        fd["clipboardScore"] = 0
        fd["clickNumEvents"] = 0
        fd["mouseNumEvents"] = 0
        fd["touchNumEvents"] = 0

        // Capabilities
        fd["gpu"] = getGPUInfo()
        fd["bluetooth"] = "Unknown"
        fd["touchSupport"] = "true"
        fd["googleAppSetID"] = "Unknown"

        return fd
    }

    private func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    private func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
        #endif
    }

    private func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    private func getTotalDiskSpace() -> Int64 {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let size = attrs[.systemSize] as? Int64 {
            return size
        }
        return 0
    }

    private func getGPUInfo() -> String {
        // MTLDevice name not available without Metal import; use model-based inference
        return getModelIdentifier()
    }
}
