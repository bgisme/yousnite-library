import Vapor
import Fluent
import JWT

public struct GoogleController {
    public init() { }
    
    struct GoogleAuthResponse: Content {
        let credential: String
        let gState: String
        
        init(_ req: Request) throws {
            let cookies = req.cookies.all
            guard let bodyCSRFToken: String = req.content["g_csrf_token"],
                  let gCSRFToken = cookies["g_csrf_token"]?.string,
                  gCSRFToken == bodyCSRFToken,
                  let credential: String = req.content["credential"],
                  let gState = cookies["g_state"]?.string
            else {
                throw Abort(.unauthorized)
            }
            self.credential = credential
            self.gState = gState
        }
    }
}

// MARK: - Configure
extension GoogleController {
    static public private(set) var clientId = ""
    
    static func configure() throws {
        guard
            let clientId = Environment.get("GOOGLE_CLIENT_ID")/*,
            let clientSecret = Environment.get("GOOGLE_CLIENT_SECRET")*/
        else {
            throw Abort(.internalServerError)
        }
        self.clientId = clientId
    }
}

// MARK: - RouteCollection
extension GoogleController: RouteCollection {
    public func boot(routes: any RoutesBuilder) throws {
        
    }
}
