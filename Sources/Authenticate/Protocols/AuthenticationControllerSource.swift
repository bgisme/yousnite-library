import Vapor
import Fluent

public enum AuthenticationMethod: Codable {
    case email(_ address: String, passwordHash: String)
    case apple(email: String, id: String)
    case google(email: String, id: String)
}

public protocol AuthenticationControllerSource {
    static func createUser(_ method: AuthenticationMethod, db: Database) async throws -> any Authenticatable
    static func user(_ method: AuthenticationMethod, db: Database) async throws -> (any Authenticatable)?
    static func verify(_ password: String, for user: any Authenticatable, db: Database) throws -> Bool
    static func isSignedIn(req: Request) -> Bool
    static func authenticate(_ user: any Authenticatable, req: Request)
    static func unauthenticate(isSessionEnd: Bool, req: Request)
}
