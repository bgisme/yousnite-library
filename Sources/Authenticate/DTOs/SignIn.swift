import Vapor


public struct SignIn: Content {
    public let email: Email
    public let password: Password
    
    public init(email: Email, password: Password) {
        self.email = email
        self.password = password
    }
    
    public init(from decoder: any Decoder) throws {
        self.email = try Email(from: decoder)
        self.password = try Password(from: decoder)
    }
}
