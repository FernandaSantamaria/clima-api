import ClimaApi
import Vapor


var env = try Environment.detect()

try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

try configure(app)
try app.run()


func printDatabaseConfig() {
    let host = Environment.get("DATABASE_HOST") ?? "no definido"
    let port = Environment.get("DATABASE_PORT") ?? "no definido"
    let user = Environment.get("DATABASE_USERNAME") ?? "no definido"
    let password = Environment.get("DATABASE_PASSWORD") ?? "no definido"
    let dbName = Environment.get("DATABASE_NAME") ?? "no definido"

    print("""
    Configuración de la base de datos:
    Host: \(host)
    Port: \(port)
    Usuario: \(user)
    Password: \(password)
    Database: \(dbName)
    """)
}
