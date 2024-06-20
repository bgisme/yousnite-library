import Vapor
import Fluent
import JWTKit

public struct MainController: Sendable {
    public init() { }
}

// MARK: - Configure
extension MainController {
    public static var delegate: MainDelegate.Type!
    
    public static func configure(app: Application,
                                 delegate: MainDelegate.Type,
                                 emailDelegate: EmailDelegate.Type,
                                 emailSender: String,
                                 viewDelegate: ViewDelegate.Type) throws {
        self.delegate = delegate
        
        try UserController.configure(app: app)
        
        /// configure sources
        try AppleController.configure()
        try EmailController.configure(app: app,
                                      delegate: emailDelegate,
                                      sender: emailSender)
        try GoogleController.configure()
        
        /// JWT
        app.jwt.apple.applicationIdentifier = AppleController.servicesId
        let signer = try JWTSigner.es256(key: .private(pem: AppleController.jwkKey))
        app.jwt.signers.use(signer, kid: .init(string: AppleController.jwkId), isDefault: false)

        try ViewController.configure(delegate: viewDelegate)
    }
}

// MARK: - RouteCollection
extension MainController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        // these routes are separate from Apple + Google sign-in-up redirect URI
        // that's handled entirely by the ViewController
        try routes.grouped("email").register(collection: EmailController())
        try routes.grouped("apple").register(collection: AppleController())
        try routes.grouped("google").register(collection: GoogleController())
//        routes.get("deleteUser", use: deleteUser)
    }
    
//    func deleteUser(req: Request) async throws -> HTTPStatus {
        /// If user is authenticated... can delete own account...
        /// If user is authorized... can delete any account"
//        guard let d = Self.delegate else { throw Abort(.internalServerError) }
//        return try await d.delete(user, req: req)
//    }
}
