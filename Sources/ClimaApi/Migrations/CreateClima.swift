import Fluent

struct CreateClima: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("climas")
            .id()
            .field("ubicacion", .string, .required)
            .field("temperatura", .double, .required)
            .field("condition", .string, .required)
            .field("outfit", .string, .required)
            .field("date", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("climas").delete()
    }
}