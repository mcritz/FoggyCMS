import Fluent
import Vapor

final class AssetController: RouteCollection {
    let logger = Logger(label: "AssetController")
    
    func boot(routes: RoutesBuilder) throws {
        let assetGroup = routes.grouped("assets")
        assetGroup.get(use: index)
    }
    
    func index(req: Request) throws -> EventLoopFuture<[Asset]> {
        Asset.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<Asset> {
        try req.content
            .decode(Asset.self)
            .save(on: req.db)
            .transform(to: Asset())
    }
}
