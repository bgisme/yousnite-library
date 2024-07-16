import Vapor

extension Logger {
    public func critical(_ message: String,
                         _ fields: [String: String],
                         file: String = #fileID,
                         function: String = #function,
                         line: UInt = #line) {
        critical(.init(message), metadata: fields.mapValues{.string($0)}, file: file, function: function, line: line)
    }
    
    public func info(_ message: String,
                     _ fields: [String: String],
                     file: String = #fileID,
                     function: String = #function,
                     line: UInt = #line) {
        info(.init(message), metadata: fields.mapValues{.string($0)}, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String,
                        _ fields: [String: String],
                        file: String = #fileID,
                        function: String = #function,
                        line: UInt = #line) {
        warning(.init(message), metadata: fields.mapValues{.string($0)}, file: file, function: function, line: line)
    }
}

extension Logger.Message {
    init(_ stringLiteral: String) {
        self.init(stringLiteral: stringLiteral)
    }
}
