import Vapor

struct OutfitController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let outfitRoutes = routes.grouped("api", "outfits")
        outfitRoutes.get(use: index)
    }

    func index(req: Request) async throws -> [Outfit] {
    try await Outfit.query(on: req.db).all()
}

}
