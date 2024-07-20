import Vapor

public enum Kind {
    case invite
    case passwordReset
    case passwordUpdate
}

public protocol SESv2Delegate {
    func subject(_: Kind) -> String
    
    func body(_: Kind, link: String) -> String
}
