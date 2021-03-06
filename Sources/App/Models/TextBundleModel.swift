import Fluent
import TextBundle
import Vapor

final class TextBundleModel: Model, Content {
    static var schema = "textbundle"
    
    init() { }
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    @Field(key: "textContents")
    var textContents: String
    @Field(key: "assetURLs")
    var assetURLs: [URL]?
    // TODO: Handle this
//    @Field(key: "meta")
//    var meta: TextBundle.Metadata
}

extension TextBundleModel {
    convenience init(with bundle: TextBundle) {
        self.init()
        self.name = bundle.name
        self.textContents = bundle.textContents
        self.assetURLs = bundle.assetURLs
    }
}

extension TextBundleModel {
    func saveAssets(on req: Request) throws {
        guard let assetURLs = assetURLs else { return }
        _ = try assetURLs.map { url in
            try Asset(url).save(on: req.db)
        }
    }
}
