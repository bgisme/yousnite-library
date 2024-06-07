import Foundation

extension TimeInterval {
    static func minutes(_ qty: Double) -> TimeInterval { qty * 60 }
    
    static func hours(_ qty: Double) -> TimeInterval { minutes(qty * 60) }
    
    static func days(_ qty: Double) -> TimeInterval { hours(qty * 24) }
    
    static func weeks(_ qty: Double) -> TimeInterval { days(qty * 7) }
}
