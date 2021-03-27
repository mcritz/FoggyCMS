import Fluent
import Vapor

final class AssetController: RouteCollection {
    let logger = Logger(label: "AssetController")
    
    func boot(routes: RoutesBuilder) throws {
        let assetGroup = routes.grouped("assets")
        assetGroup.get(use: index)
        assetGroup.post(use: create)
        assetGroup.group(":assetID") { asset in
            asset.get(use: getOne)
        }
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
    
    func getOne(req: Request) throws -> EventLoopFuture<Response> {
        return Asset.find(req.parameters.get("assetID"),
                       on: req.db)
            .flatMapThrowing { maybeAsset in
                guard let asset = maybeAsset else {
                    throw Abort(.notFound)
                }
                return req.fileio.streamFile(at: asset.filepath)
            }
    }
}
