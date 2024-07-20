import Vapor

extension APIController: RouteCollection {
    public func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped(Self.routes)
        api.post(Self.signInRoute, use: signIn)
        api.get(Self.signOutRoute, use: signOut)
    }
    
    func signIn(req: Request) async throws -> Response {
        guard try req.credential == nil else {
            // already authenticated
            return .init(status: .ok)
        }
        let response = req.redirect(to: EmailController.signInPath(), redirectType: .permanentPost)
        return response.setIsAPI()
    }
    
    func signOut(req: Request) async throws -> Response {
        MainController.unauthenticate(isSessionEnd: true, req: req)
        return .init(status: .ok)
    }
}
