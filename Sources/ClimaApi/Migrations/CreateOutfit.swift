import Fluent

struct CreateOutfit: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("outfits")
            .id()
            .field("nombre", .string, .required)
            .field("descripcion", .string, .required)
            .field("temperatura_min", .double, .required)
            .field("temperatura_max", .double, .required)
            .field("imagen", .string)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("outfits").delete()
    }
}