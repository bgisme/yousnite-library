public protocol PasswordUpdateView {
    var email: String { get }
    var isNewUser: Bool { get }
    var postTo: String { get }
    var error: String? { get }
}

public protocol PasswordUpdateInvalidView {
    var error: String { get }
}
