public protocol EmailJoinView {
    var email: String? { get }
    var postTo: String { get }
    var signInPath: String { get }
    var error: String? { get }
}
