struct TyradsInitResponse: Codable {
    let code: Int
    let message: String
    let timestamp: Int
    let responseTime: Double
    let data: TyradsInitData
}

struct TyradsInitData: Codable {
    let newRegisteredUser: Bool
    let newRegisteredDevice: Bool
    let accountInfo: TyradsAccountInfo
    let appInfo: TyradsAppInfo
    let token: String

    enum CodingKeys: String, CodingKey {
        case newRegisteredUser, newRegisteredDevice, accountInfo, appInfo, token
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        newRegisteredUser = try container.decodeIfPresent(Bool.self, forKey: .newRegisteredUser) ?? false
        newRegisteredDevice = try container.decodeIfPresent(Bool.self, forKey: .newRegisteredDevice) ?? false
        accountInfo = try container.decode(TyradsAccountInfo.self, forKey: .accountInfo)
        appInfo = try container.decode(TyradsAppInfo.self, forKey: .appInfo)
        token = try container.decodeIfPresent(String.self, forKey: .token) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(newRegisteredUser, forKey: .newRegisteredUser)
        try container.encode(newRegisteredDevice, forKey: .newRegisteredDevice)
        try container.encode(accountInfo, forKey: .accountInfo)
        try container.encode(appInfo, forKey: .appInfo)
        try container.encode(token, forKey: .token)
    }
}

struct TyradsAccountInfo: Codable {
    let id: Int
    let publisherUserId: String
}

struct TyradsAppInfo: Codable {
    let headerColor: String
    let mainColor: String
    let premiumColor: String

    enum CodingKeys: String, CodingKey {
        case headerColor, mainColor, premiumColor
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headerColor = try container.decodeIfPresent(String.self, forKey: .headerColor) ?? ""
        mainColor = try container.decodeIfPresent(String.self, forKey: .mainColor) ?? ""
        premiumColor = try container.decodeIfPresent(String.self, forKey: .premiumColor) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(headerColor, forKey: .headerColor)
        try container.encode(mainColor, forKey: .mainColor)
        try container.encode(premiumColor, forKey: .premiumColor)
    }
}
