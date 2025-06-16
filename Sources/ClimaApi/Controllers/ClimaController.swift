import Vapor 
import Fluent

struct ClimaController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let clima = routes.grouped("clima")
        clima.get("recomendar", use: getClimaYRecomendarOutfit)
    }

    func getClimaYRecomendarOutfit(req: Request) async throws -> OutfitResponse {
        // Obtener parámetros de la query
        guard let location = try? req.query.get(String.self, at: "ubicacion") else {
            throw Abort(.badRequest, reason: "Falta el parámetro 'ubicacion'")
        }
        let genero = try req.query.get(String.self, at: "genero")

        // Preparar URL para OpenWeather
        let apiKey = Environment.get("OPENWEATHER_API_KEY") ?? "4c055129c7b61b72ed27f7ec80bf56a9"
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
        let urlString = "https://api.openweathermap.org/data/2.5/weather?q=\(encodedLocation)&appid=\(apiKey)&units=metric"
        let uri = URI(string: urlString)

        req.logger.info("Conectando a OpenWeather: \(urlString)")

        do {
            let response = try await req.client.get(uri)

            guard response.status == .ok else {
                if let body = response.body {
                    req.logger.error("Error en respuesta: \(String(buffer: body))")
                }
                throw Abort(.badRequest, reason: "No se pudo obtener el clima para '\(location)'")
            }

            let weatherResponse = try response.content.decode(WeatherAPIResponse.self)
            let temperatura = weatherResponse.main.temp
            let condition = weatherResponse.weather.first?.main ?? "Desconocido"
            let climaClasificado = clasificarClima(condition: condition, temperatura: temperatura)

            // Buscar outfit en la base de datos
            guard let outfit = try await Outfit.query(on: req.db)
                .filter(\.$nombre == climaClasificado)
                .filter(\.$genero == genero.lowercased())
                .first()
            else {
                throw Abort(.notFound, reason: "No se encontró outfit para clima \(climaClasificado) y género \(genero)")
            }

            // Construir URL de imagen (ajústala según tu entorno)
            let baseURL = Environment.get("BASE_URL") ?? "http://localhost:8080"
            let imagenURL = "\(baseURL)/imagenes/outfits/\(climaClasificado)/\(genero.lowercased())/\(outfit.imagen)"

            // Crear y guardar el registro en la BD
            let climaGuardado = Clima(
                ubicacion: location,
                temperatura: temperatura,
                condition: condition,
                outfit: outfit.descripcion,
                date: Date()
            )
            try await climaGuardado.save(on: req.db)

            // Crear respuesta
            return OutfitResponse(
                ubicacion: location,
                temperatura: temperatura,
                clima: climaClasificado,
                genero: genero,
                descripcion: outfit.descripcion,
                imagen: imagenURL,
                condition: condition,
                date: ISO8601DateFormatter().string(from: Date())
            )

        } catch {
            req.logger.error("Error: \(error)")
            throw Abort(.internalServerError, reason: "Error al procesar la solicitud: \(error.localizedDescription)")
        }
    }

    // Clasificación de clima personalizada
    func clasificarClima(condition: String, temperatura: Double) -> String {
        if temperatura < 10 {
            return "frio"
        } else if temperatura < 20 {
            return "templado"
        } else if temperatura < 30 {
            return "calido"
        } else {
            return "caluroso"
        }
    }
}


struct OutfitResponse: Content {
    let ubicacion: String
    let temperatura: Double
    let clima: String
    let genero: String
    let descripcion: String
    let imagen: String
    let condition: String
    let date: String
}
