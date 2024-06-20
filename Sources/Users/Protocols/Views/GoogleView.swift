public protocol GoogleView {
    var clientId: String { get }
    var redirectUri: String { get }
    var error: String? { get }
}
