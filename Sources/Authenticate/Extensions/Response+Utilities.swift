import Vapor

extension Response {
    func setAuthenticationCookies(state: String,
                                  isJoin: Bool = false,
                                  isAPI: Bool = false,
                                  expires seconds: Int = 300) {
        cookies[AppleController.cookieKey] = .init(string: state,
                                                   expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                   maxAge: seconds,
                                                   isHTTPOnly: true,
                                                   sameSite: HTTPCookies.SameSitePolicy.none)
        cookies[GoogleController.cookieKey] = .init(string: state,
                                                    expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                    maxAge: seconds,
                                                    isHTTPOnly: true,
                                                    sameSite: HTTPCookies.SameSitePolicy.none)
        if isJoin { setIsJoin() }
        if isAPI { setIsAPI() }
    }
    
    @discardableResult
    func setIsJoin(expires seconds: Int = 300) -> Response {
        cookies[MainController.joinCookieKey] = .init(string: .init(true),
                                                      expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                      maxAge: seconds,
                                                      isHTTPOnly: true,
                                                      sameSite: HTTPCookies.SameSitePolicy.none)
        return self
    }
    
    @discardableResult
    func setIsAPI(expires seconds: Int = 300) -> Response {
        cookies[APIController.cookieKey] = .init(string: .init(true),
                                                 expires: Date().addingTimeInterval(.init(TimeInterval(seconds))),
                                                 maxAge: seconds,
                                                 isHTTPOnly: true,
                                                 sameSite: HTTPCookies.SameSitePolicy.none)
        return self
    }
    
    func deleteAuthenticationCookies() {
        cookies[AppleController.cookieKey] = nil
        cookies[GoogleController.cookieKey] = nil
        cookies[MainController.joinCookieKey] = nil
        cookies[APIController.cookieKey] = nil
    }

}
