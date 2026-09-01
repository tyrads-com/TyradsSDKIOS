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
        let deviceType = device.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        fd["deviceId"] = device.identifierForVendor?.uuidString ?? ""
        fd["device"] = deviceType
        fd["deviceName"] = device.name
        fd["brand"] = "Apple"
        fd["model"] = deviceType
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
        fd["installerStore"] = getInstallerStore()
        fd["osLang"] = Locale.current.languageCode ?? "en"

        // Security
        fd["rooted"] = isJailbroken()
        fd["virtual"] = isSimulator()

        // Network
        fd["connectionType"] = networkDetails["connectionType"] ?? "Unknown"

        // SDK info
        fd["sdkVersion"] = TyradsSDKConfig.sdkVersion
        fd["sdkPlatform"] = "Swift"

        // Memory
        fd["totalMemory"] = getTotalMemoryGB()

        // Placeholder interaction metrics (iOS does not expose these natively)
        fd["keyboardNumEvents"] = 0
        fd["keyboardScore"] = 0
        fd["clipboardNumEvents"] = 0
        fd["clipboardScore"] = 0
        fd["clickNumEvents"] = 0
        fd["mouseNumEvents"] = 0
        fd["touchNumEvents"] = 0

        // Capabilities
        fd["gpu"] = "Unknown"
        fd["bluetooth"] = "Unknown"
        fd["touchSupport"] = "Unknown"
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

    private func getInstallerStore() -> String {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return "Unknown" }
        switch receiptURL.lastPathComponent {
        case "receipt":
            return "com.apple.appstore"
        case "sandboxReceipt":
            return FileManager.default.fileExists(atPath: receiptURL.path)
                ? "com.apple.testflight"
                : "com.apple.xcode"
        default:
            return "Unknown"
        }
    }

    private func getTotalMemoryGB() -> String {
        let bytes = ProcessInfo.processInfo.physicalMemory
        let gb = Double(bytes) / 1_073_741_824.0
        return String(format: "%.2f", gb)
    }
}
