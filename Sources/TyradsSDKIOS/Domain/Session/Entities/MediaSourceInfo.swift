public struct TyradsMediaSourceInfo {
    /// Name of the source where user was acquired
    public let mediaSourceName: String?
    /// Name of campaign used to acquire user
    public let mediaCampaignName: String?
    /// ID of the source where user was acquired
    public let mediaSourceId: String?
    /// Sub-source ID
    public let mediaSubSourceId: String?
    /// Whether user acquisition was via incentivized channels
    public let incentivized: Bool?
    /// Name of ad set used to acquire user
    public let mediaAdsetName: String?
    /// ID of ad set used to acquire user
    public let mediaAdsetId: String?
    /// Name of creative used to acquire user
    public let mediaCreativeName: String?
    /// ID of creative used to acquire user
    public let mediaCreativeId: String?
    /// Custom field. Not received on postback.
    public let sub1: String?
    /// Custom field. Not received on postback.
    public let sub2: String?
    /// Custom field. Can be sent back on postback.
    public let sub3: String?
    /// Custom field. Can be sent back on postback.
    public let sub4: String?
    /// Custom field. Not received on postback.
    public let sub5: String?

    public init(
        mediaSourceName: String? = nil,
        mediaCampaignName: String? = nil,
        mediaSourceId: String? = nil,
        mediaSubSourceId: String? = nil,
        incentivized: Bool? = nil,
        mediaAdsetName: String? = nil,
        mediaAdsetId: String? = nil,
        mediaCreativeName: String? = nil,
        mediaCreativeId: String? = nil,
        sub1: String? = nil,
        sub2: String? = nil,
        sub3: String? = nil,
        sub4: String? = nil,
        sub5: String? = nil
    ) {
        self.mediaSourceName = mediaSourceName
        self.mediaCampaignName = mediaCampaignName
        self.mediaSourceId = mediaSourceId
        self.mediaSubSourceId = mediaSubSourceId
        self.incentivized = incentivized
        self.mediaAdsetName = mediaAdsetName
        self.mediaAdsetId = mediaAdsetId
        self.mediaCreativeName = mediaCreativeName
        self.mediaCreativeId = mediaCreativeId
        self.sub1 = sub1
        self.sub2 = sub2
        self.sub3 = sub3
        self.sub4 = sub4
        self.sub5 = sub5
    }
}
