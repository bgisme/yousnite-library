import Vapor

extension HTTPCookies {
    public func bool(_ key: String) -> Bool {
        Bool(self.all[key]?.string ?? "false")!
    }
}
