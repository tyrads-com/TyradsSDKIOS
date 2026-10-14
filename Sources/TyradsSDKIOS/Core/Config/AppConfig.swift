import UIKit

public enum TyradsSDKConfig {
    static let apiVersion = "4.0"
    static let sdkVersion = "4.0.0"
    static let sdkPlatform = "Swift"
    static let baseURL = "https://api.tyrads.com/v\(apiVersion)/"
    static let privacyPolicyURL = "https://tyrads.com/tyrsdk-privacy-policy/"
    static let termsOfServiceURL = "https://tyrads.com/tyrsdk-terms-of-service/"

    static let primaryColor = UIColor(red: 0/255, green: 36/255, blue: 51/255, alpha: 1)
    static let secondaryColor = UIColor(red: 2/255, green: 181/255, blue: 190/255, alpha: 1)
    static let appbarBg = UIColor(red: 0/255, green: 33/255, blue: 48/255, alpha: 1)
}
