import Fluent
import FluentMySQLDriver
import Vapor
import NIOSSL
import SwiftDotenv


// configures your application
public func configure(_ app: Application) throws {
    
    do {
        try Dotenv.load()
        print(".env cargado exitosamente")
    } catch {
        print("Error cargando el archivo .env: \(error)")
    }

    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Configuración SSL para el cliente HTTP
    var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    tlsConfiguration.certificateVerification = .none // Solo para desarrollo
    
    // Si estás en producción, usa verificación completa:
    if app.environment == .production {
        tlsConfiguration.certificateVerification = .fullVerification
    }
    
    // Configuración completa del cliente HTTP con SSL
    app.http.client.configuration = HTTPClient.Configuration(
        tlsConfiguration: tlsConfiguration,
        timeout: .init(connect: .seconds(10), read: .seconds(30))
    )
    
    // Configuración de la base de datos MySQL
    app.databases.use(.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3310, //cambio de puerto
        username: Environment.get("DATABASE_USERNAME") ?? "root",
        password: Environment.get("DATABASE_PASSWORD") ?? "root",
        database: Environment.get("DATABASE_NAME") ?? "clima_api",
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)
    
    // Agregar migraciones
    app.migrations.add(CreateClima())
    app.migrations.add(CreateOutfit())


    //Ingresar a las imagenes de outfits
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Log de configuración
    app.logger.info("Configuración completada - Cliente HTTP con SSL configurado")
    
    // register routes
    try routes(app)
}