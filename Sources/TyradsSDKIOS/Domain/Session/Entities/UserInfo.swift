public struct TyradsUserInfo {
    /// Email address — used to identify user and prevent fraud
    public let email: String?
    /// Phone number. Replace + with 00, e.g. 0015555551234 for US number.
    public let phoneNumber: String?
    /// User segment group for reward tiering, e.g. "High purchasing user"
    public let userGroup: String?
    public let age: Int?
    public let gender: Int?

    public init(
        email: String? = nil,
        phoneNumber: String? = nil,
        userGroup: String? = nil,
        age: Int? = nil,
        gender: Int? = nil
    ) {
        self.email = email
        self.phoneNumber = phoneNumber
        self.userGroup = userGroup
        self.age = age
        self.gender = gender
    }
}
