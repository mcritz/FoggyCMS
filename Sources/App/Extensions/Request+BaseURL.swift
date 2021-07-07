import Vapor

extension Request {
    func baseURL() throws -> URL {
        let hostName = self.application.http.server.configuration.hostname
        let port = self.application.http.server.configuration.port
        guard let appBaseURL = URL(string: "\(hostName):\(port)") else {
            throw Abort(.internalServerError)
        }
        return appBaseURL
    }
}
