import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }
    app.get("healthcheck") { _ -> String in "OK" }
    try app.register(collection: TodoController())
    try app.register(collection: TextBundleController())
}
