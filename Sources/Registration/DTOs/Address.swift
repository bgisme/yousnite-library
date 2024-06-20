public struct StreetAddress: Codable {
    public let street1: String
    public let street2: String?
    public let street3: String?
    public let city: String
    public let state: StateCode
    public let zip: ZipCode
}
