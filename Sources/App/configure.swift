import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
    
    #if DEBUG
    app.databases.use(.postgres(hostname: "localhost", username: "mcritz", password: "vapor"), as: .psql)
    #else
    fatalError("Production DB not configured!")
    #endif
    
    app.migrations.add(CreateTodo())
    app.migrations.add(CreateTextBundle())
    
    #if DEBUG
    print("migating dev db")
    try app.autoMigrate().wait()
    #else
    fatalError("Did not migrate db")
    #endif
}
