import Users

extension AWSEmail: EmailDelegate {
    public typealias Result = String
    
    public static func emailInvite(link: String,
                                   to toAddress: String,
                                   from fromAddress: String,
                                   as fromName: String) async throws -> Result? {
        let invite = try AWSEmail.email(from: fromName,
                                        instruction: "Click to finish the process.",
                                        buttonTitle: "Register",
                                        href: link,
                                        disclaimer: "Ignore if not requested.")
        return try await invite.send(to: toAddress,
                                     from: fromAddress,
                                     as: fromName,
                                     subject: "Invitation to join...")
    }
    
    public static func emailPasswordReset(link: String,
                                          to toAddress: String,
                                          from fromAddress: String,
                                          as fromName: String) async throws -> Result? {
        let reset = try AWSEmail.email(from: fromName,
                                       instruction: "Click to reset password.",
                                       buttonTitle: "Reset",
                                       href: link,
                                       disclaimer: "Ignore if not requested. Nothing has changed with your account.")
        return try await reset.send(to: toAddress,
                                    from: fromAddress,
                                    subject: "Password reset requested...")
    }
    
    public static func emailPasswordUpdated(to toAddress: String,
                                            from fromAddress: String,
                                            as fromName: String) async throws -> Result? {
        let updated = try AWSEmail.email(from: fromName,
                                         message: "Your password has been updated.",
                                         disclaimer: "Contact us immediately if not requested.")
        return try await updated.send(to: toAddress,
                                      from: fromAddress,
                                      as: fromName,
                                      subject: "Password updated...")
    }
}
