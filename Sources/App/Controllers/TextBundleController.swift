import Fluent
import TextBundle
import Vapor

struct TextBundleController: RouteCollection {
    
    let logger = Logger(label: "TextBundleController")
    
    func boot(routes: RoutesBuilder) throws {
        let texts = routes.grouped("textbundles")
        texts.get(use: index)
        texts.post(use: create)
        texts.group(":id") { textReq in
            textReq.get(use: getOne)
        }
        
        texts.on(.POST, "upload", body: .stream, use: upload)
        //post("upload", use: upload)
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
    
    /// Intended entry point for naming files
    /// - Parameter headers: Source `HTTPHeaders`
    /// - Returns: `String` with best guess file name.
    private func filename(with headers: HTTPHeaders) -> String {
        let fileNameHeader = headers["File-Name"]
        if let inferredName = fileNameHeader.first {
            return inferredName
        }
        
        let fileExt = fileExtension(for: headers)
        return "upload-\(UUID().uuidString).\(fileExt)"
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
    
    
    
    func upload(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let logger = Logger(label: "TextBundle.upload")
        let statusPromise = req.eventLoop.makePromise(of: HTTPStatus.self)
        
        let tempFilePath = FileManager.default.temporaryDirectory
            .path
            .appending(UUID().uuidString)
            .appending(".textpack")
        
        logger.debug(Logger.Message(stringLiteral: "Handling: \(tempFilePath)"))
        
        guard FileManager.default.createFile(atPath: tempFilePath,
                                       contents: nil,
                                       attributes: nil) else {
            logger.critical("Could not upload \(tempFilePath)")
            throw Abort(.internalServerError)
        }
        
        // Configure SwiftNIO to create a file stream.
        let nbFileIO = req.application.fileio
        let fileHandle = nbFileIO.openFile(path: tempFilePath,
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
                        // Handle errors by closing and removing our file
                        try? fHand.close()
                        try FileManager.default.removeItem(atPath: tempFilePath)
                    } catch {
                        debugPrint("catastrophic failure on \(errz)", error)
                    }
                    // Inform the client
                    statusPromise.succeed(.internalServerError)
                    
                case .end:
                    drainPromise.succeed(())
                    try? fHand.close()
                    logger.debug(Logger.Message(stringLiteral: "tempFilePath: \(tempFilePath)"))
                    // TODO: Uploads
                    statusPromise.succeed(.ok)
//                    _ = upload
//                        .save(on: req.db)
//                        .map { _ in
//                        statusPromise.succeed(.ok)
//                    }
                }
                return drainPromise.futureResult
            }
        }.transform(to: statusPromise.futureResult)
    }

    
//    func upload(req: Request) throws -> EventLoopFuture<String> {
//        let resultPromise = req.eventLoop.makePromise(of: String.self)
//
//        let fileHandle = req.application
//            .fileio
//            .openFile(path: UUID().uuidString.appending(".textpack"),
//                      eventLoop: req.eventLoop)
//        return fileHandle.map { fhand, kCFBundle in
//                req.body.drain { streamResult in
//                    switch streamResult {
//                    case .buffer(let buffy):
//                        logger.debug(Logger.Message(stringLiteral: buffy.debugDescription))
//                    case .error(let error):
//                        logger.error(Logger.Message(stringLiteral: error.localizedDescription))
//                        resultPromise.fail(error.localizedDescription)
//                    case .end:
//                        logger.info("Done")
//                        resultPromise.succeed("Done")
//                    }
//                    return resultPromise.futureResult()
//                }
//        }
//        .transform(to: resultPromise.futureResult)
//    }
}