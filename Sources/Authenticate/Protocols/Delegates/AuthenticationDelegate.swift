import Vapor
import Fluent

public protocol AuthenticationUserDelegate: Sendable {
    func createUser(on: Database) async throws -> UUID
    
    func deleteUser(id: UUID, on: Database) async throws
    
//    func createUser(_ method: CredentialMethod, on: Database) async throws -> any UserIdentifiable
    
//    func user(_ method: CredentialMethod, on: Database) async throws -> any UserIdentifiable
    
//    func authentication(req: Request) throws -> any UserIdentifiable
    
//    func authenticate(_ user: any UserIdentifiable, req: Request) throws
    
//    func unauthenticate(isSessionEnd: Bool, req: Request)
    
//    func delete(_ user: any UserIdentifiable, req: Request) async throws
}

//public protocol MethodAuthenticatable: Authenticatable, ModelAuthenticatable {
//    var email: String { get }
//                
//    func update(_ method: CredentialMethod) throws -> any UserIdentifiable
//    
//    func save(on db: Database) async throws
//    
//    func delete(force: Bool, on db: Database) async throws
//}

public enum CredentialMethod: Codable {
    case apple(email: String, id: String)
    case email(_ address: String, password: String = Password.random())
    case google(email: String, id: String)
    
    var email: String {
        switch self {
        case .apple(let email, _): email
        case .email(let address, _): address
        case .google(let email, _): email
        }
    }
    
    var type: CredentialType {
        switch self {
        case .email: .email
        case .apple: .apple
        case .google: .google
        }
    }
}
