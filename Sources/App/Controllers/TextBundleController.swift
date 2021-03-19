import Fluent
import TextBundle
import Vapor

struct TextBundleController: RouteCollection {
    
    typealias FilePath = String
    
    let logger = Logger(label: "TextBundleController")
    
    func boot(routes: RoutesBuilder) throws {
        let texts = routes.grouped("textbundles")
        texts.get(use: index)
        texts.post(use: create)
        texts.group(":id") { textReq in
            textReq.get(use: getOne)
        }
        
        texts.on(.POST, "upload", body: .stream, use: upload)
    }
    
    func index(req: Request) throws -> EventLoopFuture<[TextBundleModel]> {
        TextBundleModel.query(on: req.db).all()
    }
    
    func create(req: Request) throws -> EventLoopFuture<TextBundleModel> {
        let textBundle = try req.content.decode(TextBundleModel.self)
        return textBundle.save(on: req.db).transform(to: textBundle)
    }
    
    func getOne(req: Request) throws -> EventLoopFuture<TextBundleModel> {
           guard let id: UUID = req.parameters.get("id") else {
               throw Abort(.badRequest)
           }
           return TextBundleModel.find(id, on: req.db).flatMapThrowing {
               guard let found = $0 else {
                   throw Abort(.noContent)
               }
               return found
           }
    }
    
    /// Reads a `Request`’s Content-Type and returns a suitable extension
    /// - Parameter req: `Request` with Content-Type Header
    /// - Throws: if the Content-Type doesn’t match an expected type
    /// - Returns: `String` for a file extension
    private func getExtension(_ req: Request) throws -> String {
        let contentType = req.headers["Content-Type"].first
        switch contentType {
        case "textbundle":
            logger.debug("uploading textbundle")
            return ".textbundle"
        case "textpack":
            logger.debug("uploading textpack")
            return ".textpack"
        case "application/octet-stream":
            logger.debug("random bits")
            return ".bin"
        default:
            logger.critical("invalid mediaType")
            throw Abort(.badRequest)
        }
    }
    
    /// Parse the header’s Content-Type to determine the file extension
    /// - Parameter headers: source `HTTPHeaders`
    /// - Returns: `String` guess at appropriate file extension
    private func fileExtension(for headers: HTTPHeaders) -> String {
        var fileExtension = "bits"
        if let contentType = headers.contentType {
            switch contentType {
            case .jpeg:
                fileExtension = "jpg"
            case .mp3:
                fileExtension = "mp3"
            case .init(type: "video", subType: "mp4"):
                fileExtension = "mp4"
            default:
                fileExtension = "bits"
            }
        }
        return fileExtension
    }
    
    /// Creates a temporary file, returning its path
    /// - Parameters:
    ///   - fileName: `String` the name of the file itself. Ex: “Foo.textpack”
    /// - Throws: if the file creation is not successful
    /// - Returns: `String` the
    private func createUploadFile(_ fileName: String) throws -> FilePath {
        let tempFilePath = FileManager.default.temporaryDirectory
            .path
            .appending(fileName)
        
        logger.debug(Logger.Message(stringLiteral: "Handling: \(tempFilePath)"))
        
        guard FileManager.default.createFile(atPath: tempFilePath,
                                       contents: nil,
                                       attributes: nil) else {
            logger.critical("Could not upload \(tempFilePath)")
            throw Abort(.internalServerError)
        }
        return tempFilePath
    }
    
    /// Reads a `TextBundle` at a path and saves it on the `Request`
    /// - Parameters:
    ///   - path: `FilePath` of the source `TextBundle`
    ///   - req: `Request` to save results on
    /// - Throws: if `FilePath` is invalid or save is unsucessful
    /// - Returns: `EventLoopFuture<TextBundle>`
    private func extractTextBundle(_ path: FilePath, req: Request) throws -> EventLoopFuture<TextBundle> {
        guard let bundleURL = URL(string: path) else {
            throw Abort(.internalServerError, reason: "Could not extract TextBundle.")
        }
        
        let diskTextBundle = try TextBundle.read(bundleURL)
        try diskTextBundle.saveAssets(on: req)
        return TextBundleModel(with: diskTextBundle)
            .save(on: req.db)
            .transform(to: diskTextBundle)
    }
    
    /// Uploads a `TextBundle`
    /// - Parameter req: `Request` with `Content-Type` header set to `textpack` or `textbundle`
    /// - Throws: for bad content
    /// - Returns: `EventLoopFuture<TextBundle>`
    func upload(req: Request) throws -> EventLoopFuture<TextBundle> {
        let logger = Logger(label: "TextBundle.upload")
        let resultPromise = req.eventLoop.makePromise(of: TextBundle.self)
        let ext = try getExtension(req)
        let fileName = UUID().uuidString.appending(ext)
        
        // Configure SwiftNIO to create a file stream.
        let nbFileIO = req.application.fileio
        let filePath = try createUploadFile(fileName)
        let fileHandle = nbFileIO.openFile(path: filePath,
                                           mode: .write,
                                           eventLoop: req.eventLoop)
        
        // Launch the stream…
        return fileHandle.flatMapThrowing { fHand in
            // Vapor request will now feed us bytes
            req.body.drain { someResult -> EventLoopFuture<Void> in
                let drainPromise = req.eventLoop.makePromise(of: Void.self)
                
                switch someResult {
                case .buffer(let buffy):
                    // We have bytes. So, write them to disk, and handle our promise
                    _ = nbFileIO.write(fileHandle: fHand,
                                   buffer: buffy,
                                   eventLoop: req.eventLoop)
                        .always { outcome in
                            switch outcome {
                            case .success(let yep):
                                drainPromise.succeed(yep)
                            case .failure(let err):
                                drainPromise.fail(err)
                            }
                    }
                case .error(let errz):
                    do {
                        drainPromise.fail(errz)
                        try fHand.close()
                        try FileManager.default.removeItem(atPath: filePath)
                        logger.error("Failed to upload. \(filePath) \n Reason: \n \(errz.localizedDescription)")
                    } catch {
                        logger.error("Failed to upload. \n Reason: \n \(error.localizedDescription) \n File \(filePath) will need to be removed manually.")
                        debugPrint("catastrophic failure on \(errz)", error)
                    }
                    // Inform the client
                    resultPromise.fail(Abort(.internalServerError))
                case .end:
                    do {
                        logger.debug(Logger.Message(stringLiteral: "Uploaded: \(filePath)"))
                        _ = try extractTextBundle(filePath, req: req).flatMapThrowing { bundle in
                            try? fHand.close()
                            resultPromise.succeed(bundle)
                        }
                    } catch {
                        try? fHand.close()
                        resultPromise.fail(error)
                    }
                    drainPromise.succeed(())
                }
                return drainPromise.futureResult
            }
        }.transform(to: resultPromise.futureResult)
    }
    
}
