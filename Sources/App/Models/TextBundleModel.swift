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
