public protocol EmailSignInView {
    var email: String? { get }
    var postTo: String { get }
    var joinPath: String { get }
    var passwordResetPath: String { get }
    var error: String? { get }
}
