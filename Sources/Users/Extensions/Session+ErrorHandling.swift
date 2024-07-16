import Vapor
import Utilities

extension Session {
    public typealias AuthenticationError = UserController.AuthenticationError
    
    public func setAuthenticationError(_ error: AuthenticationError, key: String? = nil) {
        set(error, key: key)
    }
    
    public func joinSignInError(key: String? = nil,
                                isDeleted: Bool = false) -> UserController.JoinSignInError? {
        if let error = try? getError(AuthenticationError.self, key: key, isDeleted: isDeleted) {
            switch error {
            case .registered(let method):
                switch method {
                case .apple:
                    return .init(apple: error)
                case .email(let address):
                    return .init(error: error, address: address)
                case .google:
                    return .init(google: error)
                }
            case .notRegistered(let method),
                    .otherRegistration(let method):
                switch method {
                case .apple:
                    return .init(apple: error)
                case .email(let address):
                    return .init(error: error, address: address)
                case .google:
                    return .init(google: error)
                }
            case .passwordWrong(let email):
                return .init(error: error, address: email)
            case .passwordTokenMissingOrExpired, 
                    .service:
                break
            }
        } else if let error = try? getError(ValidateResults<Email.CodingKeys>.self, key: key, isDeleted: isDeleted) {
            if let vm = error[.email],
               let address = vm.value,
               let message = vm.message {
                return .init(error: message, address: address)
            }
            return .init(error: "Enter valid email address.")
        } else if let error = try? getError(ValidateResults<SignIn.CodingKeys>.self, key: key, isDeleted: isDeleted) {
            if let vm = error[.email],
               let message = vm.message {
                // return error message
                return .init(error: message)
            } else if let vm = error[.password],
                      let message = vm.message {
                // return email and error message
                return .init(error: message, address: error[.email]?.value)
            }
            return .init(error: "Enter your credentials.")
        } else if let message = try? getErrorMessage(key: key, isDeleted: isDeleted) {
            return .init(error: message)
        }
        return nil
    }
    
    public func passwordResetError(key: String? = nil,
                                   isDeleted: Bool = false) -> UserController.PasswordResetError? {
        if let error = try? getError(AuthenticationError.self, key: key, isDeleted: isDeleted) {
            switch error {
            case .notRegistered(let method):
                switch method {
                case .apple:
                    return .init(error: error)
                case .email(let address):
                    return .init(error: error, email: address)
                case .google:
                    return .init(error: error)
                }
            default: break
            }
        } else if let message = try? getErrorMessage(key: key, isDeleted: isDeleted) {
            return .init(error: message)
        }
        return nil
    }
    
    public func passwordSetError(key: String? = nil,
                                 isDeleted: Bool = false) -> UserController.PasswordSetError? {
        if let error = try? getError(AuthenticationError.self, key: key, isDeleted: isDeleted) {
            switch error {
            case .passwordTokenMissingOrExpired:
                return .init(error: error)
            default: break
            }
        } else if let error = try? getError(ValidateResults<Password.CodingKeys>.self, key: key, isDeleted: isDeleted) {
            if let vm = error[.password],
               let message = vm.message {
                return .init(error: message)
            } else if let vm = error[.confirm],
                      let message = vm.message {
                return .init(error: message)
            } else {
                return .init(error: "Enter a valid password twice.")
            }
        } else if let message = try? getErrorMessage(key: key, isDeleted: isDeleted) {
            return .init(error: message)
        }
        return nil
    }
    
//    public func signOutError(key: String? = nil,
//                             isDeleted: Bool = false) -> UserController.SignOutError? {
//        if let error = try? getError(AuthenticationError.self, key: key, isDeleted: isDeleted) {
//            switch error {
//            default: break
//            }
//        } else if let message = try? getErrorMessage(key: key, isDeleted: isDeleted) {
//            return .init(error: message)
//        }
//        return nil
//    }
}
