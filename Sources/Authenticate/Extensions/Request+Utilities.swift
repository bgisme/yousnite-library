import Vapor

extension Request {
    public var isAuthenticated: Bool {
        self.auth.has(Credential.self)
    }
    
    var credential: Credential? {
        auth.get(Credential.self)
    }
    
    public var userId: UUID? {
        credential?.userId
    }
    
    public var userEmail: String? {
        credential?.email
    }
    
    public var userType: CredentialType? {
        credential?.type
    }
}
