import Vapor
import Fluent

extension EmailController {
    public enum EmailKind: Codable {
        case invite(link: String)
        case joined(_ AuthenticationKind: CredentialType)
        case passwordReset(link: String)
        case passwordSet
        case unjoined(_ AuthenticationKind: CredentialType)
        
        var description: String {
            switch self {
            case .invite: "invite"
            case .joined: "joined"
            case .passwordReset: "passwordReset"
            case .passwordSet: "passwordSet"
            case .unjoined: "unjoined"
            }
        }
    }
        
    static func sendPasswordCreateResetLink(to toAddress: String,
                                            isNewUser: Bool,
                                            isAPI: Bool = false,
                                            req: Request) async throws {
        // check conflicts... new user but one exists... not new user and one does not exist
        let method = CredentialMethod.email(toAddress)
        var other: CredentialType?
        let isExisting = (try? await MainController.credential(method, other: &other, on: req.db)) != nil
        let isCreate = isNewUser && !isExisting
        let isReset = !isNewUser && isExisting
        // user must be new and not exist or not new and existing
        guard isCreate || isReset else {
            let error: MainController.CredentialError
            error = isCreate ? .registered(.email(toAddress)) : .notRegistered(.email(toAddress))
            throw error
        }
        // user with same email and other authentication must not exist
        guard other == nil else {
            let error: MainController.CredentialError
            error = .otherRegistration(other!.method(email: toAddress))
            throw error
        }
        do {
            // create token and send email
            let state = try await createToken(to: toAddress, db: req.db).state
            let link: String
            if isAPI {
                link = isCreate ? APIController.passwordSetPath(isAbsolute: true, state: state) : APIController.passwordResetPath(isAbsolute: true, state: state)
            } else {
                link = isCreate ? ViewController.passwordSetPath(isAbsolute: true, state: state) :
                ViewController.passwordResetPath(isAbsolute: true, state: state)
            }
            let kind: EmailKind = isCreate ? .invite(link: link) : .passwordReset(link: link)
            try await sendEmail(kind, to: toAddress, req: req)
        } catch {
            // only invite and password-reset email errors get thrown
            req.session.set(error)
        }
    }
    
    static func sendEmail(_ kind: EmailKind,
                          to toAddress: String,
                          req: Request) async throws {
        do {
            let purpose: EmailPurpose
            switch kind {
            case .invite(let link):
                purpose = .invite(link: link, toAddress: toAddress)
            case .joined(let type):
                purpose = .joined(toAddress: toAddress, type: type)
            case .passwordReset(let link):
                purpose = .passwordReset(link: link, toAddress: toAddress)
            case .passwordSet:
                purpose = .passwordUpdated(toAddress: toAddress)
            case .unjoined(let type):
                purpose = .quit(toAddress: toAddress, type: type)
            }
            try await MainController.notificationDelegate.email(purpose, req: req)
        } catch {
            req.logger.critical("Email Failed", [
                "to": toAddress,
                "kind": kind.description,
                "error": error.localizedDescription,
            ])
            switch kind {
            case .invite, .passwordReset:
                throw error
            default:
                // other kinds are just notification... user will not miss them
                break
            }
        }
    }
    
    static func email(for state: String,
                      deleteOthersWithEmail isOthersDeleted: Bool = false,
                      db: Database) async throws -> String? {
        // fetch password token for state value
        guard let pt = try await EmailToken
            .query(on: db)
            .filter(\.$state == state)
            .first()
        else {
            return nil
        }
        if isOthersDeleted {
            // delete all records with email... in case user made multiple requests
            let all = try await EmailToken
                .query(on: db)
                .filter(\.$email == pt.email)
                .all()
            for each in all {
                try await each.delete(on: db)
            }
        }
        return !pt.isExpired ? pt.email : nil
    }
}
