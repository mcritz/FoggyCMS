@testable import App
import TextBundle
import XCTVapor

final class TextBundleModelTests: XCTestCase {
    
    var jsonHeaders = HTTPHeaders([
        ("Content-Type", "application/json")
    ])
    
    let testBundle = TextBundle(name: "test", contents: "Hello, World", assetURLs: nil)
    
    
    func testTextBundle() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let testData = try! JSONEncoder().encode(testBundle)
        let testBytes = ByteBuffer(data: testData)
        
        try app.test(.POST, "textbundles", headers: jsonHeaders, body: testBytes, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            do {
                let saved = try res.content.decode(TextBundleModel.self)
                XCTAssertEqual(saved.name, testBundle.name)
                XCTAssertEqual(saved.textContents, testBundle.textContents)
                let savedID = saved.id
                XCTAssertNotNil(savedID)
            } catch {
                XCTFail("Could not decode saved model")
            }
            
        })
    }
}
