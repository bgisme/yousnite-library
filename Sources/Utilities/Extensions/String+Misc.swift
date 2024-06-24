import Foundation

extension String {
    
    public func isOnly(_ sets: CharacterSet...) -> Bool {
        var set = CharacterSet()
        for other in sets { set.formUnion(other) }
        return self.rangeOfCharacter(from: set) != nil && self.rangeOfCharacter(from: set.inverted) == nil
    }
    
    public func isNumeric(ignoreDiacritics: Bool = false) -> Bool {
        guard !isEmpty else { return false }
        if ignoreDiacritics {
            return range(of: "[^0-9]", options: .regularExpression) == nil
        }
        return rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789").inverted) == nil
    }
    
    public func only(_ sets: CharacterSet...) -> String {
        var u = self.unicodeScalars
        for set in sets {
            u = u.filter{set.contains($0)}
        }
        return String(u)
    }
    
    public func addingCharacterReturnsAndLineFeeds() -> String {
        let cr = String(Character(UnicodeScalar(13)))
        let lf = String(Character(UnicodeScalar(10)))
        return self.replacingOccurrences(of: "<CRLF>", with: cr+lf)
    }
}
