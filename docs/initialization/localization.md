# Localization

This method allows you to change the language used by the Tyrads SDK at runtime. It updates the SDK's internal locale settings and refreshes the premium widget content.

```swift
// Supported codes: en, es, id, ja, ko, zh-Hans-CN
Tyrads.instance.changeLanguage("es") // Change to Spanish
```

#### Parameters:

* `languageCode` (`String`): A string representing the desired language code (e.g. `"en"` for English, `"es"` for Spanish, `"id"` for Indonesian). This should be a valid ISO 639-1 language code.

#### Usage Example:

```swift
Button("Change to Spanish") {
    Tyrads.instance.changeLanguage("es")
}
```

#### Notes:

* This method fetches translations from the Tyrads backend and persists the selected language so it persists between app sessions.
* Make sure your application and the Tyrads SDK support the language code you are passing, otherwise English will be used.
* This method is asynchronous under the hood (network fetch), but does not need to be awaited.
* Consider providing a language selection UI in your application if you want users to choose their preferred language.
