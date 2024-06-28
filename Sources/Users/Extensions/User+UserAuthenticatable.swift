import Vapor
import Fluent

extension User: UserAuthenticatable {
    public convenience init(_ method: AuthenticationMethod) throws {
        let (email, type, value) = Self.emailTypeValue(method)
        try self.init(email: email, type: type, value: value)
    }
    
    public func update(_ method: AuthenticationMethod) throws -> any UserAuthenticatable {
        let (email, type, value) = Self.emailTypeValue(method)
        self.email = email
        self.type = type
        if type == .email {
            try setPassword(value)
        } else {
            self.value = value
        }
        return self
    }
    
    private static func emailTypeValue(_ method: AuthenticationMethod) -> (String, AuthenticationType, String) {
        let email: String
        let type: AuthenticationType
        let value: String
        
        switch method {
        case .apple(let address, let appleID):
            type = .apple
            email = address
            value = appleID
        case .email(let address, let password):
            type = .email
            email = address
            value = password
        case .google(let address, let googleID):
            type = .google
            email = address
            value = googleID
        }
        return (email, type, value)
    }
}
