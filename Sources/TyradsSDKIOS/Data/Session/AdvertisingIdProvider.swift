import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

// MARK: - AdvertisingIdProvider (Data)
// Platform IDFA / ATT resolution. Mirrors the Flutter SDK:
//   authorized -> IDFA
//   limited    -> IDFV (identifierForVendor)
//   still empty -> custom ad id fallback

final class TyradsAdvertisingIdProvider: TyradsAdvertisingIdProviding {
    func resolve(fallbackId: String) async -> TyradsAdvertisingIdentifier {
        var identifierType = "IDFA"
        var advertisingId: String?

        if #available(iOS 14, *) {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            if status == .authorized {
                advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            } else {
                identifierType = "OTHER"
                advertisingId = await vendorId()
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            } else {
                identifierType = "OTHER"
                advertisingId = await vendorId()
            }
        }

        if advertisingId == nil || advertisingId!.isEmpty {
            identifierType = "OTHER"
            advertisingId = fallbackId
        }

        return TyradsAdvertisingIdentifier(
            identifierType: identifierType,
            identifier: advertisingId ?? "NA"
        )
    }

    private func vendorId() async -> String? {
        await MainActor.run { UIDevice.current.identifierForVendor?.uuidString }
    }
}
