import Fluent
import Vapor

// Estructuras para OpenWeatherMap API
struct WeatherDescription: Content {
    let main: String
    let description: String
} 

struct Rain : Content {
    let oneHour : Double?
    enum CodingKeys: String, CodingKey{
        case oneHour="1h"
    }
}

struct WeatherMain: Content {
    let temp: Double
    let feels_like: Double
    let humidity: Double
}

struct WeatherWind: Content {
    let speed: Double
}

struct Coord: Content {
    let lon: Double
    let lat: Double
}

struct WeatherResponse: Content {
    let weather :[WeatherDescription]
    let main: WeatherMain
    let wind: WeatherWind
    let coord: Coord
    let timezone: Int
    let rain: Rain?
}

struct UVResponse: Content {
    let value: Double
}

// Struct para la respuesta de recomendación
struct RecomendacionResponse: Content {
    let ubicacion: String
    let temperatura: Double
    let condicion: String
    let recomendacion: String
    let error: Bool
}

//check conexion con clouding
func routes(_ app: Application) throws {
    app.get { req in
    return "¡Hola desde Vapor en Clouding!"
}

    //new endpoint 
    app.get("clima", "recomendar") { req async throws -> RecomendacionResponse in
        let ubicacion = try req.query.get(String.self, at: "ubicacion")
        req.logger.info("/clima/recomendar called with ubicacion=\(ubicacion)")

        let apiKey = Environment.get("OPENWEATHER_API_KEY") ?? ""
        let weatherURL = URI(string: "http://api.openweathermap.org/data/2.5/weather")

        let weatherResponse = try await req.client.get(weatherURL) { get in
            try get.query.encode(["q": ubicacion, "appid": apiKey, "units": "metric"] )
        }
        guard weatherResponse.status == .ok else {
            req.logger.error("Weather API returned status \(weatherResponse.status)")
            throw Abort(.badRequest, reason: "Error fetching weather data")
        }
        let weather = try weatherResponse.content.decode(WeatherResponse.self)

        let temp = weather.main.temp
        let outfit: String = {
            switch temp {
            case ..<10: return "Usa abrigo, bufanda y botas"
            case ..<20: return "Chaqueta ligera y jeans"
            case ..<30: return "Camiseta y pantalón cómodo"
            default: return "Ropa ligera, gafas de sol y gorra"
            }
        }()

        return RecomendacionResponse(
            ubicacion: ubicacion,
            temperatura: temp,
            condicion: weather.weather.first?.description ?? "No disponible",
            recomendacion: outfit,
            error: false
        )
    }

    app.get("weather-outfit") { req async throws -> [String: String] in

        let city = try req.query.get(String.self, at: "city")
        let genero = try req.query.get(String.self, at: "genero")
    
        req.logger.info("🔍 Ruta /weather-outfit con city=\(city), genero=\(genero)")

        //DEBBUUUUUUG ing
        guard let city = req.query[String.self, at: "city"] else {
            throw Abort(.badRequest, reason: "Missing 'city' parameter")
        }

        let client = req.client
        let apiKey = Environment.get("OPENWEATHER_API_KEY") ?? "9c99901dd0dee1abf65d4a6cc3217238"
        req.logger.info("Haciendo solicitud al clima...")

        let weatherURL = URI(string: "http://api.openweathermap.org/data/2.5/weather?q=\(city)&appid=\(apiKey)&units=metric")

        // 1. Obtener clima actual con manejo de errores SSL
        let weatherResponse: ClientResponse
        do {
            weatherResponse = try await client.get(weatherURL)
        } catch {
            req.logger.error("Error SSL al obtener clima: \(error)")
            throw Abort(.internalServerError, reason: "Error de conexión SSL con OpenWeatherMap")
        }

        guard weatherResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Error getting weather data: \(weatherResponse.status)")           
        }

        let weather = try weatherResponse.content.decode(WeatherResponse.self)
        let condition = weather.weather.first?.description ?? "No disponible"
        let temp = weather.main.temp
        let feelsLike = weather.main.feels_like
        let humidity = weather.main.humidity
        let wind = weather.wind.speed
        let lat = weather.coord.lat
        let lon = weather.coord.lon


        // 2. Obtener índice UV con lat/lon usando HTTP
        let uvRequestURL = URI(string: "http://api.openweathermap.org/data/2.5/uvi?appid=\(apiKey)&lat=\(lat)&lon=\(lon)")
        let uvResponse: ClientResponse
        do {
            uvResponse = try await client.get(uvRequestURL)
        } catch {
            req.logger.error("Error SSL al obtener UV: \(error)")
            throw Abort(.internalServerError, reason: "Error de conexión SSL al obtener índice UV")
        }

        guard uvResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Error getting UV index: \(uvResponse.status)")
        }

        let uv = try uvResponse.content.decode(UVResponse.self).value

        // 3. Generar recomendación de outfit con imagen
        let isRaining = weather.rain?.oneHour ?? 0 > 0
        let isWindy = wind > 10

        var outfit = ""
        var imagenNombre = ""

        if temp < 10 {
            outfit = "Usa abrigo, bufanda y botas"
            imagenNombre = genero == "mujer" ? "frio1M.png" : "frio1H.png"
        } else if temp < 20 {
            outfit = "Chaqueta ligera y jeans"
            imagenNombre = genero == "mujer" ? "viento3M.png" : "viento1H.png"
        } else if temp < 30 {
            outfit = "Camiseta y pantalón cómodo"
            imagenNombre = genero == "mujer" ? "calor3M.png" : "calor3H.png"
        } else {
            outfit = "Ropa ligera, gafas de sol y gorra"
            imagenNombre = genero == "mujer" ? "calor1M.png" : "calor1H.png"
        }

    // Construir URL absoluta para la imagen con base en la petición (host + ruta)
    guard let baseURL = req.url.schemeAndHost else {
        throw Abort(.internalServerError, reason: "No se pudo obtener la URL base")
    }
    let imagenURL = "\(baseURL)/images/outfits/\(imagenNombre)"

        try await consulta.save(on: req.db)

        return [
             "outfit": outfit,
             "temperatura": "\(temp)°C",
             "sensacion_termica": "\(feelsLike)°C",
             "humedad": "\(humidity)%",
             "viento": "\(wind) m/s",
             "uv": "\(uv)",
             "hora_local": localTime,
             "is_lloviendo": isRaining ? "Sí" : "No",
             "imagen_url": imagenURL

             ]
    }

    try app.register(collection: OutfitController())
    try app.register(collection: ClimaController())
    
}