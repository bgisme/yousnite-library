public protocol PasswordSetView {
    var isNewUser: Bool { get }
    var postTo: String? { get }
    var joinPath: String { get }
    var signInPath: String { get }
    var requirements: String? { get }
    var error: String? { get }
}
