import Foundation

// MARK: - LoginUserUseCase (Domain)
// Builds the login payload from session inputs + device/advertising info and
// delegates the network call to the auth repository.

struct TyradsLoginParams {
    let userID: String
    let engagementId: String?
    let placementId: String?
    let mediaSourceInfo: TyradsMediaSourceInfo?
    let userInfo: TyradsUserInfo?
}

struct TyradsLoginUserUseCase {
    let authRepository: TyradsAuthRepository
    let deviceInfo: TyradsDeviceInfoProviding
    let advertisingId: TyradsAdvertisingIdProviding
    let session: TyradsSessionStore

    func callAsFunction(_ params: TyradsLoginParams) async throws -> TyradsLoginResult {
        let fallbackId = session.customAdvertisingId()
        async let adIdTask = advertisingId.resolve(fallbackId: fallbackId)
        async let deviceTask = deviceInfo.deviceDetails()
        async let apnsTokenTask = TyradsAPNsManager.shared.waitForToken()
        let adId = await adIdTask
        let device = await deviceTask
        let apnsToken = await apnsTokenTask

        var fd: [String: Any] = [
            "publisherUserId": params.userID,
            "platform": "iOS",
            "deviceData": device,
            "identifierType": adId.identifierType,
            "identifier": adId.identifier,
        ]

        if let apnsToken {
            fd["devicePushToken"] = apnsToken
        }
        if let eid = params.engagementId, !eid.isEmpty { fd["engagementId"] = Int(eid) }
        if let pid = params.placementId, !pid.isEmpty { fd["placementId"] = Int(pid) }

        merge(params.mediaSourceInfo, into: &fd)
        merge(params.userInfo, into: &fd)

        return try await authRepository.initialize(payload: fd)
    }

    private func merge(_ media: TyradsMediaSourceInfo?, into fd: inout [String: Any]) {
        guard let m = media else { return }
        if let v = m.sub1 { fd["sub1"] = v }
        if let v = m.sub2 { fd["sub2"] = v }
        if let v = m.sub3 { fd["sub3"] = v }
        if let v = m.sub4 { fd["sub4"] = v }
        if let v = m.sub5 { fd["sub5"] = v }
        if let v = m.mediaSourceName { fd["mediaSourceName"] = v }
        if let v = m.mediaSourceId { fd["mediaSourceId"] = v }
        if let v = m.mediaSubSourceId { fd["mediaSubSourceId"] = v }
        if let v = m.incentivized { fd["incentivized"] = v }
        if let v = m.mediaAdsetName { fd["mediaAdsetName"] = v }
        if let v = m.mediaAdsetId { fd["mediaAdsetId"] = v }
        if let v = m.mediaCreativeName { fd["mediaCreativeName"] = v }
        if let v = m.mediaCreativeId { fd["mediaCreativeId"] = v }
        if let v = m.mediaCampaignName { fd["mediaCampaignName"] = v }
    }

    private func merge(_ user: TyradsUserInfo?, into fd: inout [String: Any]) {
        guard let u = user else { return }
        if let v = u.email { fd["email"] = v }
        if let v = u.phoneNumber { fd["phoneNumber"] = v }
        if let v = u.userGroup { fd["userGroup"] = v }
        if let v = u.age { fd["age"] = v }
        if let v = u.gender { fd["gender"] = v }
    }
}
