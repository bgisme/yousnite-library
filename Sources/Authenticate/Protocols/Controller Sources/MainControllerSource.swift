import Vapor
import Fluent

public protocol MainControllerSource {
    static func createUser(_ method: AuthenticationMethod, on: Database) async throws -> any UserAuthenticatable
    
    static func user(_ method: AuthenticationMethod, on: Database) async throws -> (any UserAuthenticatable)?
    
    static func authenticatedUser(req: Request) throws -> (any UserAuthenticatable)?
    
    static func authenticate(_ user: any UserAuthenticatable, req: Request) throws
    
    static func unauthenticate(isSessionEnd: Bool, req: Request)
}

public protocol UserAuthenticatable: Authenticatable, ModelAuthenticatable {
    var email: String { get }
    
//    init(_ method: AuthenticationMethod) throws   ...not sure why but this won't work
            
    func set(_ method: AuthenticationMethod) throws -> any UserAuthenticatable
    
    func save(on db: Database) async throws
}

public enum AuthenticationMethod: Codable {
    case email(_ address: String, password: String = Password.random())
    case apple(email: String, id: String)
    case google(email: String, id: String)
}
