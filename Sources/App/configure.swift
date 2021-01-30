import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // DB Setup
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    
    // Migrations
    app.migrations.add(CreateVote())
    app.migrations.add(CreateCandidate())
    try app.autoMigrate().wait()
    
    // Frontend
    app.views.use(.leaf)

    // Auth
    let candidateAdminAuthenticator = AdminMiddleware<CandidateRequest>(administrators: ["1CdPoF9cvw3YEiuRCHxdsGpvb5tSUYBBo"])
    
    // register routes
    try app.register(collection: VoteController())
    try app.register(collection: CandidateController(adminAuthenticator: candidateAdminAuthenticator))
}
