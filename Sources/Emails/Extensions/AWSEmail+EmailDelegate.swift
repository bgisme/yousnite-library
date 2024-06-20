import Users

extension AWSEmail: EmailDelegate {
    public typealias Result = String
    
    public static func emailInvite(link: String,
                                   to address: String,
                                   from sender: String) async throws -> Result? {
        let invite = try AWSEmail.email(sender: sender,
                                        instruction: "Click to finish the process.",
                                        buttonTitle: "Register",
                                        href: link,
                                        disclaimer: "Ignore if not requested.")
        return try await invite.send(to: address, from: sender, subject: "Invitation to join...")
    }
    
    public static func emailPasswordReset(link: String,
                                          to address: String,
                                          from sender: String) async throws -> Result? {
        let reset = try AWSEmail.email(sender: sender,
                                       instruction: "Click to reset password.",
                                       buttonTitle: "Reset",
                                       href: link,
                                       disclaimer: "Ignore if not requested. Nothing has changed with your account.")
        return try await reset.send(to: address, from: sender, subject: "Password reset requested...")
    }
    
    public static func emailPasswordUpdated(to address: String,
                                            from sender: String) async throws -> Result? {
        let updated = try AWSEmail.email(sender: sender,
                                         message: "Your password has been updated.",
                                         disclaimer: "Contact us immediately if not requested.")
        return try await updated.send(to: address, from: sender, subject: "Password updated...")
    }
}
