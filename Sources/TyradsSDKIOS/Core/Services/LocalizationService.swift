import Foundation

final class TyradsLocalizationService {
    static let shared = TyradsLocalizationService()

    private(set) var currentLanguage: String = "en"
    private var translations: [String: Any] = [:]
    private var supportedLocales: [String] = []
    private let fallbackLocale = "en"
    private let prefs = UserDefaults.standard
    private let network = TyradsNetworkManager.shared

    private init() {}

    // MARK: - Public

    func initialize(languageCode: String) {
        currentLanguage = languageCode
        Task { await loadTranslations(locale: languageCode) }
    }

    func changeLanguage(_ languageCode: String) {
        currentLanguage = languageCode
        UserDefaults.standard.set(languageCode, forKey: TyradsKeyNames.language)
        Task { await loadTranslations(locale: languageCode) }
    }

    func localizedString(_ key: String) -> String {
        translate(key)
    }

    // MARK: - Load

    private func loadTranslations(locale: String) async {
        let hasUpdate = await checkForUpdate(locale: locale)

        if !hasUpdate, let cached = prefs.string(forKey: "translations_\(locale)"),
           let data = cached.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            await MainActor.run { translations = json }
            return
        }

        await fetchTranslations(locale: locale)
    }

    private func fetchTranslations(locale: String) async {
        var resolvedLocale = locale
        if !supportedLocales.isEmpty && !supportedLocales.contains(locale) {
            resolvedLocale = fallbackLocale
        }

        do {
            let data = try await network.requestData(
                endpoint: "translations/\(resolvedLocale)",
                queryParams: ["format": "nested"]
            )
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
            await MainActor.run { translations = json }
            prefs.set(String(data: data, encoding: .utf8), forKey: "translations_\(resolvedLocale)")
        } catch {
            // Network failed — fall back to bundled .strings
            loadBundledFallback(locale: resolvedLocale)
            print("[TyradsSDK] Localization fetch failed, using bundled fallback: \(error)")
        }
    }

    private func checkForUpdate(locale: String) async -> Bool {
        do {
            let data = try await network.requestData(endpoint: "translations/version")
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let list = json["data"] as? [[String: Any]] else { return false }

            supportedLocales = list.compactMap { $0["code"] as? String }

            guard let entry = list.first(where: { $0["code"] as? String == locale }),
                  let remoteSha = entry["sha256"] as? String else { return false }

            let cachedSha = prefs.string(forKey: "cached_version_\(locale)")
            if remoteSha != cachedSha {
                prefs.removeObject(forKey: "cached_version_\(locale)")
                prefs.set(remoteSha, forKey: "cached_version_\(locale)")
                return true
            }
        } catch {
            print("[TyradsSDK] Localization version check failed: \(error)")
        }
        return false
    }

    // MARK: - Translate

    private func translate(_ key: String) -> String {
        let keys = key.split(separator: ".").map(String.init)
        var current: Any = translations

        for k in keys {
            guard let dict = current as? [String: Any], let next = dict[k] else {
                return bundledFallback(key) ?? key
            }
            current = next
        }

        return (current as? String) ?? bundledFallback(key) ?? key
    }

    // MARK: - Bundled fallback

    private func loadBundledFallback(locale: String) {
        // No-op: bundledFallback() reads from .strings on demand.
    }

    private func bundledFallback(_ key: String) -> String? {
        let lang = supportedLocales.contains(currentLanguage) ? currentLanguage : fallbackLocale
        guard
            let path = Bundle.module.path(forResource: lang, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return Bundle.module.localizedString(forKey: key, value: nil, table: nil)
        }
        let result = bundle.localizedString(forKey: key, value: nil, table: nil)
        return result == key ? nil : result
    }
}
