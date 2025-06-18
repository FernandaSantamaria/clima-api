import Fluent
import FluentMySQLDriver
import Vapor
import NIOSSL
import SwiftDotenv


public func configure(_ app: Application) throws {

    // Configuración SSL para el cliente HTTP
    var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    tlsConfiguration.certificateVerification = .none // Solo para desarrollo
    
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
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 3306, //cambio de puerto de 3310-3306 con bd en ubuntu
        username: Environment.get("DATABASE_USER") ?? "clima_user",
        password: Environment.get("DATABASE_PASSWORD") ?? "clima_pass",
        database: Environment.get("DATABASE_NAME") ?? "clima_db",
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)
    
    // Agregar migraciones
    //Primero outfit porque clima depende de outfit
        app.migrations.add(CreateOutfit())
        app.migrations.add(CreateClima())


    //Ingresar a las imagenes de outfits
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    // Log de configuración
    app.logger.info("Configuración completada - Cliente HTTP con SSL configurado")
    
    // register routes
    try routes(app)

    // Mantener la app despierta
   // Mantener la app despierta cada 14 minutos
    let interval: TimeInterval = 840

    DispatchQueue.global().async {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            app.logger.info("Keep-alive ping")
        }
        RunLoop.current.run()
    }


// Configurar CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .contentType, .authorization]
    )

    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))

    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080
    app.http.server.configuration.hostname = Environment.get("HOST") ?? "0.0.0.0"


}


