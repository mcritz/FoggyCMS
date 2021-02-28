import Foundation
import Fluent

struct CreateTextBundle: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TextBundleModel.schema)
            .id()
            .field("name", .string, .required)
            .field("textContents", .string, .required)
            .field("assetURLs", .array(of: .json))
            .field("meta", .json)
            .create()
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TextBundleModel.schema).delete()
    }
}
