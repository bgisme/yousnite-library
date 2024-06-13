import Vapor
import Fluent

public struct MainController { }
    
// MARK: - Configure
extension MainController {
    public static func configure(app: Application,
                                 source: MainControllerSource.Type,
                                 emailSource: EmailSource.Type,
                                 emailSender: String,
                                 viewControllerSource: ViewControllerSource.Type) throws {
        self.source = source
        try AppleController.configure()
        try EmailController.configure(app: app,
                                                    source: emailSource,
                                                    sender: emailSender)
        try GoogleController.configure()
        try ViewController.configure(source: viewControllerSource)
    }
}

// MARK: - Utilities
extension MainController {
    public static var source: MainControllerSource.Type!
    
//    public static func isExistingUser(_ method: AuthenticationMethod, db: Database) async throws -> Bool {
//        (try? await user(method, db: db)) != nil
//    }
    
//    @discardableResult
//    public static func createUser(_ method: AuthenticationMethod, db: Database) async throws -> any Authenticatable {
//        try await source.createUser(method, db: db)
//    }
    public static func createUser(_ method: AuthenticationMethod, on db: Database) async throws -> any UserAuthenticatable {
        try await source.createUser(method, on: db)
    }
    
    public static func user(_ method: AuthenticationMethod, on db: Database) async throws -> (any UserAuthenticatable)? {
        try await source.user(method, on: db)
    }
    
    public static func authenticatedUser(req: Request) throws -> (any UserAuthenticatable)? {
        try source.authenticatedUser(req: req)
    }
    
//    public static func updateAuthenticated(password: String, req: Request) async throws {
//        try await source.updateAuthenticated(password: password, req: req)
//    }
    
//    public static func verify(_ password: String, for user: any Authenticatable, db: Database) throws -> Bool {
//        try source.verify(password, for: user, db: db)
//    }

//    public static func authenticatedUser(req: Request) throws -> any Authenticatable {
//        try source.authenticatedUser(req: req)
//    }
    
//    public static func authenticatedEmail(req: Request) throws -> String {
//        try source.authenticatedEmail(req: req)
//    }
    
    public static func authenticate(_ user: any UserAuthenticatable, req: Request) throws {
        try source.authenticate(user, req: req)
    }
    
    public static func unauthenticate(isSessionEnd: Bool = true, req: Request) throws {
        source.unauthenticate(isSessionEnd: isSessionEnd, req: req)
    }
}
