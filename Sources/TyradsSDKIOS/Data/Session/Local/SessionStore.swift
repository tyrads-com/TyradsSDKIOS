import Foundation

// MARK: - SessionStore (Data / Local)
// Single source of truth for session state and its UserDefaults persistence.
// Replaces the scattered prefs access and runtime flags that used to live on
// the Tyrads facade.
//
// Accessed concurrently from many tasks (login, tracking, in-app, premium
// widget) right after login, so the mutable runtime state is guarded by a
// lock. Without this, concurrent reads/writes of the String properties race on
// their reference counts and corrupt the heap.

final class TyradsSessionStore: @unchecked Sendable {
    static let shared = TyradsSessionStore()

    private let defaults = UserDefaults.standard
    private let lock = NSLock()

    private var _isSecure = false
    private var _language: String
    private var _token: String
    private var _publisherUserID: String

    private init() {
        // {lang}-{COUNTRY} (e.g. en-US, pt-BR) — preferredLanguages is already BCP-47
        // hyphenated; don't reduce it to Locale(identifier:).languageCode, which strips
        // the region.
        let deviceLanguage = Locale.preferredLanguages.first
        _language = defaults.string(forKey: TyradsKeyNames.language)
            ?? deviceLanguage
            ?? "en-US"
        _token = defaults.string(forKey: TyradsKeyNames.token) ?? ""
        _publisherUserID = defaults.string(forKey: TyradsKeyNames.userId) ?? ""
    }

    private func sync<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    // MARK: Runtime session state (synchronized)

    var isSecure: Bool { sync { _isSecure } }

    var language: String {
        get { sync { _language } }
        set { sync { _language = newValue; defaults.set(newValue, forKey: TyradsKeyNames.language) } }
    }
    var token: String {
        get { sync { _token } }
        set { sync { _token = newValue; defaults.set(newValue, forKey: TyradsKeyNames.token) } }
    }
    var publisherUserID: String {
        get { sync { _publisherUserID } }
        set { sync { _publisherUserID = newValue; defaults.set(newValue, forKey: TyradsKeyNames.userId) } }
    }

    // MARK: Credentials (UserDefaults is already thread-safe)

    func persistCredentials(apiKey: String, apiSecret: String) {
        defaults.set(apiKey, forKey: TyradsKeyNames.apiKey)
        defaults.set(apiSecret, forKey: TyradsKeyNames.apiSecret)
    }

    var apiKey: String? { defaults.string(forKey: TyradsKeyNames.apiKey) }
    var apiSecret: String? { defaults.string(forKey: TyradsKeyNames.apiSecret) }

    func enableEncryption(key: String) {
        defaults.set(key, forKey: TyradsKeyNames.encryptionKey)
        sync { _isSecure = true }
    }

    var encryptionKey: String { defaults.string(forKey: TyradsKeyNames.encryptionKey) ?? "" }

    // MARK: Device identifiers

    /// Returns the stored custom ad id, generating and persisting one if absent.
    func customAdvertisingId() -> String {
        sync {
            if let existing = defaults.string(forKey: TyradsKeyNames.customAdId), !existing.isEmpty {
                return existing
            }
            let generated = UUID().uuidString
            defaults.set(generated, forKey: TyradsKeyNames.customAdId)
            return generated
        }
    }

    var apnsToken: String? {
        let value = defaults.string(forKey: TyradsKeyNames.apnsToken)
        return (value?.isEmpty == false) ? value : nil
    }

    /// The APNs token value last successfully delivered to the backend (via login
    /// or a push-token update call). Used to avoid resending an unchanged token.
    var lastSentApnsToken: String? {
        get { defaults.string(forKey: TyradsKeyNames.lastSentApnsToken) }
        set { defaults.set(newValue, forKey: TyradsKeyNames.lastSentApnsToken) }
    }

    var storedUserId: String? { defaults.string(forKey: TyradsKeyNames.userId) }

    // MARK: Privacy

    func isPrivacyAccepted(forUserId userId: String) -> Bool {
        defaults.bool(forKey: "\(TyradsKeyNames.privacyAcceptedForUserId)\(userId)")
    }

    func setPrivacyAccepted(forUserId userId: String) {
        defaults.set(true, forKey: "\(TyradsKeyNames.privacyAcceptedForUserId)\(userId)")
    }

    // MARK: Logout

    func clear() {
        defaults.removeObject(forKey: TyradsKeyNames.userId)
        defaults.removeObject(forKey: TyradsKeyNames.token)
        sync {
            _token = ""
            _publisherUserID = ""
        }
    }
}
