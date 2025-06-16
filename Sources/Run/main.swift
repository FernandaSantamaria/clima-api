import ClimaApi
import Vapor


var env = try Environment.detect()

try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

try configure(app)
try app.run()


func printDatabaseConfig() {
    let host = Environment.get("DATABASE_HOST") ?? "localhost"
    let port = Environment.get("DATABASE_PORT") ?? "3310"
    let user = Environment.get("DATABASE_USERNAME") ?? "root"
    let password = Environment.get("DATABASE_PASSWORD") ?? "root"
    let dbName = Environment.get("DATABASE_NAME") ?? "clima_api"

    print("""
    Configuración de la base de datos:
    Host: \(host)
    Port: \(port)
    Usuario: \(user)
    Password: \(password)
    Database: \(dbName)
    """)
}
