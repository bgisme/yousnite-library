import Vapor
import Fluent

public struct ClubController {
    public init() {}
}

// MARK: - Configure
extension ClubController {
    public static func configure(app: Application) throws {
        // Migrations
        app.migrations.add(Club.Migration())
    }
}
