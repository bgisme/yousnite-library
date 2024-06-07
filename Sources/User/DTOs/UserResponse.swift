import Vapor

public struct UserResponse: Content {
    public let user: User.Public
    public let accessToken: String?
    
    public init(user: User, accessToken: UserToken? = nil) throws {
        self.user = try user.asPublic()
        self.accessToken = accessToken?.value
    }
}
