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

func routes(_ app: Application) throws {
    app.get("weather-outfit") { req async throws -> [String: String] in
        guard let city = req.query[String.self, at: "city"] else {
            throw Abort(.badRequest, reason: "Missing 'city' parameter")
        }

        let client = req.client
        let apiKey = Environment.get("OPENWEATHER_API_KEY") ?? "9c99901dd0dee1abf65d4a6cc3217238"
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
        let genero = req.query[String.self, at: "genero"] ?? "mujer"


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

        // 3. Generar recomendación de outfit
        let isRaining = weather.rain?.oneHour ?? 0 > 0
        let isWindy = wind > 10

        var outfit = ""

        if temp < 10 {
            outfit = "Usa abrigo, bufanda y botas"
        } else if temp < 20 {
            outfit = "Chaqueta ligera y jeans"
        } else if temp < 30 {
            outfit = "Camiseta y pantalón cómodo"
        } else {
            outfit = "Ropa ligera, gafas de sol y gorra"
        }

        if isRaining {
             outfit += ", lleva impermeable o paraguas"
        }

        if isWindy {
            outfit += ", considera una chaqueta cortaviento"
        }

        // 4. Hora de consulta
        let nowUTC = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: weather.timezone)

        let localTime = formatter.string(from: nowUTC)

        let consulta = Clima(
            ubicacion: city,
            temperatura: temp,
            condition: condition,
            outfit: outfit,
            date: Date()
        )
        try await consulta.save(on: req.db)

        return [
             "outfit": outfit,
             "temperatura": "\(temp)°C",
             "sensacion_termica": "\(feelsLike)°C",
             "humedad": "\(humidity)%",
             "viento": "\(wind) m/s",
             "uv": "\(uv)",
             "hora_local": localTime,
             "is_lloviendo": isRaining ? "Sí" : "No"
             ]
    }

    // Nueva ruta simplificada para cumplir con el ejemplo del error
    app.get("clima", "recomendar") { req async throws -> RecomendacionResponse in
    guard let ubicacion = req.query[String.self, at: "ubicacion"] else {
        throw Abort(.badRequest, reason: "Missing 'ubicacion' parameter")
    }
        
        // Usar HTTP en lugar de HTTPS para evitar problemas SSL
        let client = req.client
        let apiKey = Environment.get("OPENWEATHER_API_KEY") ?? "9c99901dd0dee1abf65d4a6cc3217238"
        let weatherURL = URI(string: "http://api.openweathermap.org/data/2.5/weather?q=\(ubicacion)&appid=\(apiKey)&units=metric")

        let weatherResponse: ClientResponse
        do {
            weatherResponse = try await client.get(weatherURL)
        } catch {
            req.logger.error("Error SSL: \(error)")
            throw Abort(.internalServerError, reason: "Error SSL: \(String(describing: error))")
        }

        guard weatherResponse.status == .ok else {
            throw Abort(.internalServerError, reason: "Error getting weather data")           
        }

        let weather = try weatherResponse.content.decode(WeatherResponse.self)
        let temp = weather.main.temp
        let condition = weather.weather.first?.description ?? "No disponible"
        
        var outfit = ""
        if temp < 10 {
            outfit = "Usa abrigo, bufanda y botas"
        } else if temp < 20 {
            outfit = "Chaqueta ligera y jeans"
        } else if temp < 30 {
            outfit = "Camiseta y pantalón cómodo"
        } else {
            outfit = "Ropa ligera, gafas de sol y gorra"
        }
        
        return RecomendacionResponse(
            ubicacion: ubicacion,
            temperatura: temp,
            condicion: condition,
            recomendacion: outfit,
            error: false
        )
    }

    try app.register(collection: OutfitController())
    try app.register(collection: ClimaController())
}