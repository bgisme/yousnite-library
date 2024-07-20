import Vapor
import Fluent
import Utilities

public struct EmailController: Sendable {
    public init() { }
}

// MARK: - Configure
extension EmailController {
    public static func configure(app: Application,
                                 parentRouteCollection: NestedRouteCollection.Type?) throws {
        self.parentRouteCollection = parentRouteCollection
        // Migrations
        app.migrations.add(EmailToken.Migration())
    }
}

// MARK: - Tokens
extension EmailController {
    static var expires: TimeInterval = 900
    
    @discardableResult
    static func createToken(state: String = state(),
                            to email: String,
                            expiresAfter: TimeInterval = Self.expires,
                            isFailed: Bool = false,
                            db: Database) async throws -> EmailToken {
        let pt = EmailToken(state: state,
                            email: email,
                            expiresAfter: expiresAfter,
                            isFailed: isFailed)
        try await pt.save(on: db)
        return pt
    }
}

// MARK: - State
extension EmailController {
    static func state(count: Int = 32) -> String {
        [UInt8].random(count: count).base64
    }
    
    static func getState(req: Request, isNewUser: inout Bool) async throws -> String? {
        if req.isAuthenticated {
            // authenticated... submit <form> without state identifier
            isNewUser = false
            return nil
        } else if let state = req.parameters.get(stateKey),   // state is a path component
                  let toAddress = try? await email(for: state, db: req.db) {
            // unauthenticated... submit <form> with state identifier
            var other: CredentialType?
            isNewUser = (try? await MainController.credential(.email(toAddress), other: &other, on: req.db)) == nil
            return state
        } else {
            isNewUser = true
            throw MainController.CredentialError.tokenMissingOrExpired
        }
    }
}

// MARK: - Password
extension EmailController {
    static func setPassword(_ password: String, isNewUser: inout Bool, req: Request) async throws {
        // update or create password
        let toAddress: String
        let credential: Credential
        if let c = req.credential {
            isNewUser = false
            toAddress = c.email
            credential = c
            try await credential
                .update(.email(toAddress, password: password))
                .save(on: req.db)
        } else if let state = req.parameters.get(stateKey),
                  let address = try await EmailController.email(for: state,
                                                                deleteOthersWithEmail: true,
                                                                db: req.db) {
            toAddress = address
            var other: CredentialType?
            if let c = try? await MainController.credential(.email(toAddress, password: ""),
                                                                      other: &other,
                                                                      on: req.db) {
                credential = c
                isNewUser = false
                try await credential
                    .update(.email(credential.email, password: password))
                    .save(on: req.db)
            } else {
                isNewUser = true
                credential = try await MainController.createCredential(.email(toAddress, password: password), 
                                                                       on: req.db)
            }
            try MainController.authenticate(credential, req: req)
        } else {
            isNewUser = true
            throw MainController.CredentialError.tokenMissingOrExpired
        }
        // send email
        let kind: EmailController.EmailKind
        if isNewUser {
            kind = .joined(.email)
        } else {
            kind = .passwordSet
        }
        do {
            try await EmailController.sendEmail(kind, to: toAddress, req: req)
            req.logger.trace("Email Sent\ttoaddress: \(toAddress)\tkind: \(kind)")
        } catch {
            // email just notification... do not need to display for user... just log error
            req.logger.critical("Email Fail\ttoaddress: \(toAddress)\tkind: \(kind)\terror: \(error.localizedDescription)")
        }
    }
}
