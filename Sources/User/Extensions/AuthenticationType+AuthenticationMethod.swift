import Authenticate

extension User.AuthenticationType {
    public init(_ method: AuthenticationMethod) {
        switch method {
        case .email: self = .email
        case .apple: self = .apple
        case .google: self = .google
        }
    }
}
