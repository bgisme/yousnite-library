import Foundation

public enum AuthenticationType: String, Codable {
    case email
    case apple
    case google    
}

public protocol UserIdentifiable: UserAuthenticatable {
    var email: String { get }
    var authenticationType: AuthenticationType { get }
    var joinedAt: Date? { get }
    var unjoinedAt: Date? { get set }
    
    func setValue(_ value: String) throws
}
