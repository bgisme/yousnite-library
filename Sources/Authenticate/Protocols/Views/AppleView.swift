public protocol AppleView {
    var servicesId: String { get }
    var scopes: AppleScopeOptions { get }
    var redirectUri: String { get }
    var error: String? { get }
}

public struct AppleScopeOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let email = AppleScopeOptions(rawValue: 1 << 0)
    public static let name  = AppleScopeOptions(rawValue: 1 << 1)
    public static let all: AppleScopeOptions = [.email, .name]
}
