import Vapor
import Fluent

public protocol MainDelegate: Sendable {    
    func createUser(_ method: AuthenticationMethod, on: Database) async throws -> any UserIdentifiable
    
    func user(_ method: AuthenticationMethod, on: Database) async throws -> (any UserIdentifiable)?
    
    func authenticatedUser(req: Request) throws -> (any UserIdentifiable)?
    
    func authenticate(_ user: any UserIdentifiable, req: Request) throws
    
    func unauthenticate(isSessionEnd: Bool, req: Request)
    
    func delete(_ user: any UserIdentifiable, req: Request) async throws
}

public protocol UserAuthenticatable: Authenticatable, ModelAuthenticatable {
    var email: String { get }
    
//    init(_ method: AuthenticationMethod) throws   ...not sure why but this won't work
            
    func update(_ method: AuthenticationMethod) throws -> any UserIdentifiable
    
    func save(on db: Database) async throws
    
    func delete(force: Bool, on db: Database) async throws
}

public enum AuthenticationMethod: Codable {
    case email(_ address: String, password: String = Password.random())
    case apple(email: String, id: String)
    case google(email: String, id: String)
    
    var type: AuthenticationType {
        switch self {
        case .email: .email
        case .apple: .apple
        case .google: .google
        }
    }
}
