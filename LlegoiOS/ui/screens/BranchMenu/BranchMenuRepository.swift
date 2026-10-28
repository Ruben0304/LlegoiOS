//
//  BranchMenuRepository.swift
//  LlegoiOS
//
//  Cartas (menú OCR) de sucursales: búsqueda por texto y carta de una sucursal
//

import Apollo
import Foundation

struct BranchMenuInfo: Identifiable, Sendable {
    let id: String
    let branchId: String
    let imageUrl: URL?
    let ocrStatus: String
    let isActive: Bool
}

struct MenuSearchHit: Identifiable, Sendable {
    var id: String { menu.id }
    let menu: BranchMenuInfo
    let branchName: String
    let matchCount: Int
    /// Polígonos normalizados (0-1) de cada coincidencia sobre la imagen de la carta.
    let matches: [[CGPoint]]
}

@MainActor
final class BranchMenuRepository {
    private let apolloClient: ApolloClient

    init(apolloClient: ApolloClient = ApolloClientManager.shared.apollo) {
        self.apolloClient = apolloClient
    }

    func searchMenus(query: String) async throws -> [MenuSearchHit] {
        let response = try await apolloClient.fetch(
            query: LlegoAPI.SearchMenusQuery(query: query, first: 20),
            cachePolicy: .networkOnly
        )
        if let error = response.errors?.first {
            throw NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: error.message ?? "Error al buscar en las cartas"])
        }
        guard let data = response.data else {
            throw NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error al buscar en las cartas"])
        }
        return data.searchMenus.map { result in
            let menu = result.menu
            return MenuSearchHit(
                menu: BranchMenuInfo(
                    id: menu.id,
                    branchId: menu.branchId,
                    imageUrl: URL(string: menu.imageUrl),
                    ocrStatus: menu.ocrStatus,
                    isActive: menu.isActive
                ),
                branchName: result.branch?.name ?? "Sucursal",
                matchCount: result.matchCount,
                matches: result.matches.map { match in
                    match.polygon.compactMap { $0.count == 2 ? CGPoint(x: CGFloat($0[0]), y: CGFloat($0[1])) : nil }
                }
            )
        }
    }

    func fetchBranchMenu(branchId: String) async throws -> BranchMenuInfo? {
        let response = try await apolloClient.fetch(
            query: LlegoAPI.GetBranchMenuQuery(branchId: branchId),
            cachePolicy: .networkOnly
        )
        if let error = response.errors?.first {
            throw NSError(domain: "GraphQL", code: -1, userInfo: [NSLocalizedDescriptionKey: error.message ?? "Error al cargar la carta"])
        }
        guard let menu = response.data?.branchMenu else { return nil }
        return BranchMenuInfo(
            id: menu.id,
            branchId: menu.branchId,
            imageUrl: URL(string: menu.imageUrl),
            ocrStatus: menu.ocrStatus,
            isActive: menu.isActive
        )
    }
}
