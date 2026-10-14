# Deeplinking Routes

The Tyrads SDK supports deeplinking to specific sections of the offerwall. When calling `showOffers`, you can specify a route to open a particular page. For campaign-specific routes, you'll need to provide the `campaignID` as well.

| Route Name | Constant | Description |
|---|---|---|
| `offers` | `TyradsDeepRoutes.offers` | Main campaigns list (Default) |
| `active-offers` | `TyradsDeepRoutes.activeOffers` | User's activated campaigns |
| `support` | `TyradsDeepRoutes.support` | Support page (requires `campaignID`) |
| `settings` | `TyradsDeepRoutes.settings` | Settings page |

Available routes and their usage:

* `offers` - opens the Campaigns Page
* `active-offers` - opens the Activated Campaigns Page
* `support` - opens the Campaign Tickets Page (requires `campaignID`)
* `settings` - opens the Settings Page

```swift
// Note: offers is the default route when no specific route is provided
try? await Tyrads.instance.showOffers()

// Explicitly specifying the Campaigns Page
try? await Tyrads.instance.showOffers(route: TyradsDeepRoutes.offers)

// Activated Campaigns Page
try? await Tyrads.instance.showOffers(route: TyradsDeepRoutes.activeOffers)

// Specific campaign details (requires campaignID)
try? await Tyrads.instance.showOffers(campaignID: 42)

// Campaign Tickets Page (requires campaignID)
try? await Tyrads.instance.showOffers(route: TyradsDeepRoutes.support, campaignID: 42)
```
