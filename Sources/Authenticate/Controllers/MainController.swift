import Vapor
import Fluent
import JWTKit

public struct MainController { }

// MARK: - Configure
extension MainController {
    public static var source: MainControllerSource.Type!
    
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
