import Vapor
import Fluent

public struct AuthenticationController { }
    
// MARK: - Configure
extension AuthenticationController {
    public static func configure(app: Application,
                                 source: AuthenticationControllerSource.Type,
                                 emailAuthenticationSource: EmailAuthenticationSource.Type,
                                 emailProviderSource: EmailProviderSource.Type,
                                 emailSender: String,
                                 viewControllerSource: AuthenticationViewControllerSource.Type) throws {
        self.source = source
        try AppleAuthenticationController.configure()
        try EmailAuthenticationController.configure(app: app,
                                                    authenticationSource: emailAuthenticationSource,
                                                    providerSource: emailProviderSource,
                                                    sender: emailSender)
        try GoogleAuthenticationController.configure()
        try AuthenticationViewController.configure(source: viewControllerSource)
    }
}

// MARK: - Utilities
extension AuthenticationController {
    public static var source: AuthenticationControllerSource.Type!
    
    public static func isExistingUser(_ method: AuthenticationMethod, db: Database) async throws -> Bool {
        (try? await user(method, db: db)) != nil
    }
    
    @discardableResult
    public static func createUser(_ method: AuthenticationMethod, db: Database) async throws -> any Authenticatable {
        try await source.createUser(method, db: db)
    }
    
    public static func user(_ method: AuthenticationMethod, db: Database) async throws -> (any Authenticatable)? {
        try await source.user(method, db: db)
    }
    
    public static func verify(_ password: String, for user: any Authenticatable, db: Database) throws -> Bool {
        try source.verify(password, for: user, db: db)
    }

    public static func isSignedIn(req: Request) throws -> Bool {
        source.isSignedIn(req: req)
    }
    
    public static func authenticate(_ user: any Authenticatable, req: Request) throws {
        source.authenticate(user, req: req)
    }
    
    public static func unauthenticate(req: Request) throws {
        source.unauthenticate(isSessionEnd: true, req: req)
    }
}
