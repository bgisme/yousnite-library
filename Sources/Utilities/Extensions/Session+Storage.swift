import Vapor

extension Session {
    public func set<T: Encodable>(_ type: T, key: String) {
        if let data = try? JSONEncoder().encode(type.self) {
            self.data[key] = String(data: data, encoding: .utf8)
        }
    }

    public func get<T: Decodable>(_ type: T.Type, key: String, isDeleted: Bool = false) throws -> T {
        guard let data = self.data[key]?.data(using: .utf8) else {
            throw Exception(type: type, key: key)
        }
        if isDeleted { self.data[key] = nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    @discardableResult
    public func delete<T: Decodable>(_ type: T.Type, key: String) throws -> T {
        try get(type, key: key, isDeleted: true)
    }
    
    public struct Exception<T>: Error, LocalizedError {
        let type: T
        let key: String
        
        public var errorDescription: String? { "No value for '\(key)' in session." }
    }
}
