import Vapor
import Fluent
import JWTKit

public struct MainController { }

// MARK: - Configure
extension MainController {
    public static func configure(app: Application,
                                 source: MainControllerSource.Type,
                                 emailSource: EmailSource.Type,
                                 emailSender: String,
                                 viewControllerSource: ViewControllerSource.Type) throws {
        self.source = source
        
        /// configure sources
        try AppleController.configure()
        try EmailController.configure(app: app,
                                      source: emailSource,
                                      sender: emailSender)
        try GoogleController.configure()
        
        /// JWT
        app.jwt.apple.applicationIdentifier = AppleController.servicesId
        let signer = try JWTSigner.es256(key: .private(pem: AppleController.jwkKey))
        app.jwt.signers.use(signer, kid: .init(string: AppleController.jwkId), isDefault: false)

        try ViewController.configure(source: viewControllerSource)
    }
}

// MARK: - Utilities
extension MainController {
    public static var source: MainControllerSource.Type!
    
    public static func createUser(_ method: AuthenticationMethod, on db: Database) async throws -> any UserAuthenticatable {
        try await source.createUser(method, on: db)
    }
    
    public static func user(_ method: AuthenticationMethod, on db: Database) async throws -> (any UserAuthenticatable)? {
        try await source.user(method, on: db)
    }
    
    public static func authenticatedUser(req: Request) throws -> (any UserAuthenticatable)? {
        try source.authenticatedUser(req: req)
    }
    
    public static func authenticate(_ user: any UserAuthenticatable, req: Request) throws {
        try source.authenticate(user, req: req)
    }
    
    public static func unauthenticate(isSessionEnd: Bool = true, req: Request) throws {
        source.unauthenticate(isSessionEnd: isSessionEnd, req: req)
    }
}
