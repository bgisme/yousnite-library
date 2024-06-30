public enum AuthenticationType: String, Codable {
    case email
    case apple
    case google
}

public protocol UserIdentifiable: UserAuthenticatable {
    var email: String { get }
    var authenticationType: AuthenticationType { get }
}
