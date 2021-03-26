import Fluent
import TextBundle
import Vapor

extension TextBundle: Content { }

extension TextBundle {
    func saveAssets(on req: Request) throws {
        _ = try assetURLs.flatMap { urls in
            try urls.compactMap { url in
                try Asset(url).save(on: req.db)
            }
        }
    }
    
    mutating func replaceAssetURLs(with newURLs: [URL]) {
        assetURLs = newURLs
    }
}
