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
    
    func testTextPath() throws {
        let textPathExpectation = expectation(description: "Must decode TextBundle")
        textPathExpectation.expectedFulfillmentCount = 2
        textPathExpectation.assertForOverFulfill = true
        
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)
        
        let packURL = FileManager.default.temporaryDirectory
        
        try testBundle.bundle(destinationURL: packURL, compressed: true) { savedURL in
            let contentHeaders = HTTPHeaders([("Content-Type", "textpack")])
            guard let thatData = try? Data(contentsOf: savedURL) else {
                XCTFail("Could not read textpack")
                return
            }
            let thoseBytes = ByteBuffer(data: thatData)
            let _ = try? app.test(.POST, "textbundles/upload", headers: contentHeaders, body: thoseBytes, afterResponse: { res in
                
                XCTAssertEqual(res.status, HTTPStatus.ok)
                textPathExpectation.fulfill()
                
                let serverBundle = try res.content.decode(TextBundle.self)
                XCTAssertEqual(serverBundle, testBundle)
                textPathExpectation.fulfill()
                
                try? FileManager.default.removeItem(at: savedURL)
            })
            waitForExpectations(timeout: 0.5, handler: nil)
        }
    }
}
