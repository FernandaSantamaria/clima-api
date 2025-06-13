import Vapor

struct WeatherAPIResponse: Content {
    struct Main: Content {
        let temp: Double
    }

    struct Weather: Content {
        let main: String
        let description: String
    }

    let main: Main
    let weather: [Weather]
}
