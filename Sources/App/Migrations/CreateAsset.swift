import Fluent
import Vapor

struct CreateAsset: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Asset.schema)
            .id()
            .field("filename", .string, .required)
            .field("filepath", .string, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Asset.schema).delete()
    }
}
