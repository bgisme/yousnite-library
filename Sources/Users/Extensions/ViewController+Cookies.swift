import Vapor

extension ViewController {
    static let appleCookieKey = "AUTH_APPLE"
    static let googleCookieKey = "AUTH_GOOGLE"
    static let joinCookieKey = "AUTH_JOIN"
    
    static func setAuthenticationCookies(state: String,
                                         isJoin: Bool = false,
                                         expires seconds: Int = 300,
                                         response: Response) {
        response.cookies[appleCookieKey] = .init(string: state,
                                                 expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                 maxAge: seconds,
                                                 isHTTPOnly: true,
                                                 sameSite: HTTPCookies.SameSitePolicy.none)
        response.cookies[googleCookieKey] = .init(string: state,
                                                  expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                  maxAge: seconds,
                                                  isHTTPOnly: true,
                                                  sameSite: HTTPCookies.SameSitePolicy.none)
        response.cookies[joinCookieKey] = .init(string: .init(isJoin),
                                                expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                maxAge: seconds,
                                                isHTTPOnly: true,
                                                sameSite: HTTPCookies.SameSitePolicy.none)
    }
    
    static func isJoin(req: Request) -> Bool {
        let isJoin: Bool
        if let stringValue = req.cookies[Self.joinCookieKey]?.string,
           let boolValue = Bool(stringValue) {
            isJoin = boolValue
        } else {
            isJoin = false
        }
        return isJoin
    }
    
    static func deleteAuthenticationCookies(_ response: Response) {
        response.cookies[Self.appleCookieKey] = nil
        response.cookies[Self.googleCookieKey] = nil
        response.cookies[Self.joinCookieKey] = nil
    }
}
