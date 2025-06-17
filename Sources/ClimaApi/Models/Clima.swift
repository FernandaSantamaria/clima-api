import Fluent
import Vapor

final class Clima : Model, Content, @unchecked Sendable  {
    static let schema = "climas"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "ubicacion")
    var ubicacion: String

    @Field(key: "temperatura")
    var temperatura: Double

    @Field(key: "condition")
    var condition: String

    @Parent(key: "outfit")
    var outfit: Outfit 

    @Field(key: "date")
    var date: Date

    init(){}
    
    init(id: UUID? = nil, ubicacion: String, temperatura: Double, condition: String, outfit: String, date: Date = Date() ){
        self.id = id
        self.ubicacion = ubicacion
        self.temperatura = temperatura
        self.condition = condition
        self.$outfit.id = outfitID
        self.date = date


    }
}
