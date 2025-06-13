import Vapor
import Fluent

final class Outfit: Model, Content, @unchecked Sendable  {
    static let schema = "outfits"

    @ID(key: .id)
    var id: UUID?

    @Field(key:"nombre")
    var nombre: String //calor, frio, lluvia y viento

    @Field(key:"genero")
    var genero: String //hombre, mujer

    @Field(key:"descripcion")
    var descripcion: String
    
    @Field(key:"temperatura_min")
    var temperatura_min: Double

    @Field(key:"temperatura_max")
    var temperatura_max: Double

    @Field(key: "imagen")
    var imagen: String



    init() {}

    init(id: UUID? = nil, nombre: String, genero: String, descripcion: String ,temperatura_min: Double, temperatura_max: Double, imagen: String) {
        self.id = id
        self.nombre = nombre
        self.genero = genero
        self.descripcion = descripcion
        self.imagen = imagen
        self.temperatura_min = temperatura_min
        self.temperatura_max = temperatura_max
    }
}
