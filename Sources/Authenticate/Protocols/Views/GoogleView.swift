public protocol GoogleJavascriptView {
    var clientId: String { get }
    var redirectUri: String { get }
    var error: String? { get }
}

public protocol GoogleOAuthView {
    var href: String { get }
    var error: String? { get }
}
