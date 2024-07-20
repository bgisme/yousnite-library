import Vapor
import Utilities

extension MainController {
    public enum CredentialError: Error, LocalizedError, Codable {
        public enum Method: Codable {
            case apple
            case email(_ address: String)
            case google
            
            init(_ method: CredentialMethod) {
                switch method {
                case .apple(_, _): self = .apple
                case .email(let address, _): self = .email(address)
                case .google(_, _): self = .google
                }
            }
            
            init(_ type: CredentialType, _ email: String) {
                switch type {
                case .apple: self = .apple
                case .email: self = .email(email)
                case .google: self = .google
                }
            }
        }
        
        case notRegistered(_ method: Method)
        case otherRegistration(_ method: Method)
        case passwordWrong(email: String)
        case tokenMissingOrExpired
        case registered(_ method: Method)
        case service(_ method: Method)
        
        public var errorDescription: String? {
            switch self {
            case .notRegistered(let method):
                var result = "Not registered with "
                switch method {
                case .apple:
                    result += "Apple account."
                case .email(_):
                    result += "email address."
                case .google:
                    result += "Google account."
                }
                return result
            case .otherRegistration(let method):
                var result = "Already registered with "
                switch method {
                case .apple:
                    result += "your Apple account."
                case .email(_):
                    result += "same email address."
                case .google:
                    result += "your Google account."
                }
                return result
            case .passwordWrong: return "Password incorrect."
            case .tokenMissingOrExpired: return "Option expired or invalid."
            case .registered: return "Account already exists."
            case .service(let method):
                switch method {
                case .apple:
                    return "Apple service not working."
                case .email:
                    return "Internal error."
                case .google:
                    return "Google service not working."
                }
            }
        }
    }
    
    public struct JoinSignInError: Error, Codable {
        let apple: String?
        let google: String?
        let error: String?
        let address: String?
        
        init(apple: LocalizedError? = nil,
             google: LocalizedError? = nil,
             error: LocalizedError? = nil,
             address: String? = nil) {
            self.apple = apple?.localizedDescription
            self.google = google?.localizedDescription
            self.error = error?.localizedDescription
            self.address = address
        }
        
        init(error: String? = nil,
             address: String? = nil) {
            self.apple = nil
            self.google = nil
            self.error = error
            self.address = address
        }
    }
    
    public struct PasswordResetError: Error, Codable {
        let message: String
        let email: String?
        
        init(error: LocalizedError,
             email: String? = nil) {
            self.message = error.localizedDescription
            self.email = email
        }
        
        init(error message: String,
             email: String? = nil) {
            self.message = message
            self.email = email
        }
    }
    
    public struct PasswordSetError: Error, Codable {
        let message: String
        
        init(error: LocalizedError) {
            self.message = error.localizedDescription
        }
        
        init(error message: String) {
            self.message = message
        }
    }
    
    public struct SignOutError: Error, Codable {
        let message: String
        
        init(error: LocalizedError) {
            self.message = error.localizedDescription
        }
        
        init(error message: String) {
            self.message = message
        }
    }
}

extension CredentialType {
    func method(email address: String) -> MainController.CredentialError.Method {
        switch self {
        case .apple: .apple
        case .email: .email(address)
        case .google: .google
        }
    }
}
