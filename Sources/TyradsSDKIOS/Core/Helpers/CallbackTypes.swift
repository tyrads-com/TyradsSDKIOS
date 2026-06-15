public enum TyradsCallbackType {
    case campaignDetail
    case campaignActivated
    case campaignInstalled
}

public typealias TyradsCallback = ([String: Any]) -> Void
