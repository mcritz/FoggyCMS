import Vapor
import Fluent

final class Asset: Model, Content {
    static var schema = "asset"
    init() { }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "filename")
    var filename: String
    
    @Field(key: "filepath")
    var filepath: String
    
    convenience init(_ url: URL) throws {
        self.init()
        guard !url.lastPathComponent.isEmpty,
              !url.path.isEmpty else {
            throw Abort(.badRequest)
        }
        self.filename = url.lastPathComponent
        self.filepath = url.path
    }
}
