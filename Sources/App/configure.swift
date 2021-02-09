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
    let administratorAddresses = try ConfigUtils.readArray(
        "adminAddresses",
        validator: Validator.address,
        error: ConfigurationError(.badAddress, reason: "Error configuring administrators: \(ConfigurationError.Value.badAddress.reasonPhrase)")
    )
    let candidateAdminAuthenticator = AdminMiddleware<CandidateRequest>(administrators: administratorAddresses)
    
    // Excluded voters
    let excludedVoterAddresses = try ConfigUtils.readArray(
        "excludedVoters",
        validator: Validator.address,
        error: ConfigurationError(.badAddress, reason: "Error configuring excluded voters: \(ConfigurationError.Value.badAddress.reasonPhrase)")
    )
    let excludedVotersMiddleware = ExcludedVotersMiddleware<VoteRequest>(excludedVoters: excludedVoterAddresses)
    
    // register routes
    try app.register(collection: VoteController(excludedVotersMiddleware: excludedVotersMiddleware))
    try app.register(collection: CandidateController(adminAuthenticator: candidateAdminAuthenticator))
}

struct ConfigUtils {
    public static func readArray(_ envVar: String, validator: Validator<String>, error: ConfigurationError) throws -> [String] {
        let entries = Environment.get(envVar)?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? []
        
        try entries.forEach {
            let result = Validator.address.validate($0)
            guard !result.isFailure else {
                throw error
            }
        }
        
        return entries
    }
}
