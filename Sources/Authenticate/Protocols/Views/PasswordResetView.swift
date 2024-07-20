public protocol PasswordResetView {
    var postTo: String { get }
    var joinPath: String { get }
    var signInPath: String { get }
    var email: String? { get }
    var error: String? { get }
}
