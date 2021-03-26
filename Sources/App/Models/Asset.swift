import Vapor
import Fluent

final class Asset: Model, Content {
    static var schema = "asset"
    init() { }
    
    let path: String = "assets"
    
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

extension Asset {
    func makeURL(_ req: Request) throws -> URL {
        let id = try self.requireID()
        let baseURL =  try req.baseURL()
        let result =  baseURL.appendingPathComponent(path)
            .appendingPathComponent(id.uuidString)
        return result
    }
}
