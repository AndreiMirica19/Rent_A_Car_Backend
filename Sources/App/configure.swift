import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        maxConnectionsPerEventLoop: 100
    ), as: .psql)

    // register routes
    
    app.migrations.add(CreateUser())
    app.migrations.add(UsersDetails())
    app.migrations.add(AddCar())
    app.migrations.add(AddBooking())

    app.logger.logLevel = .debug
    // 3
    try app.autoMigrate().wait()
    try routes(app)
}
