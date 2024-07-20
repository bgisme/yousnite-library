import Vapor

extension HTTPCookies {
    var isJoin: Bool { bool(MainController.joinCookieKey) }
    var isAPI: Bool { bool(APIController.cookieKey) }
}
