//
//  LocalSearchRepository.swift
//  LlegoiOS
//
//  Repositorio de búsqueda offline que usa SwiftData + NLEmbedding
//  para buscar productos y negocios sin conexión a internet.
//

import Foundation
import SwiftData
import MapKit

struct LocalSearchResult {
    let products: [Product]
    let stores: [StoreWithCoordinates]
    let storeProducts: [String: [ProductGraphQL]]
}

@MainActor
final class LocalSearchRepository {

    private let embeddingService = LocalEmbeddingService.shared
    private var modelContext: ModelContext?

    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }

    // MARK: - Search Products

    func searchProducts(query: String, topK: Int = 20, minScore: Double = 0.3) -> [Product] {
        guard let ctx = modelContext else { return [] }

        var allProducts: [LocalProduct] = []

        do {
            allProducts = try ctx.fetch(FetchDescriptor<LocalProduct>())
        } catch {
            print("❌ LocalSearchRepository - Error fetching products: \(error)")
            return []
        }

        // Score combinado: vectorial + textual en el mismo pipeline.
        // La coincidencia textual exacta rescata nombres de marca que el modelo
        // no conoce (frappuccino, chanel, etc.) aunque su score vectorial sea bajo.
        let scored = allProducts.compactMap { product -> (LocalProduct, Double)? in
            let textScore = textMatch(query: query, text: "\(product.name) \(product.productDescription)")
            var vectorScore = 0.0
            if let vec = product.embedding {
                vectorScore = embeddingService.bestSimilarity(queryText: query, against: vec)
            }
            // El score final toma el mayor entre vectorial y textual.
            // Coincidencia textual exacta vale 1.0 por lo que siempre gana.
            let finalScore = max(vectorScore, textScore)
            return finalScore >= minScore ? (product, finalScore) : nil
        }
        .sorted { $0.1 > $1.1 }
        .prefix(topK)

        return scored.map { mapToProduct($0.0) }
    }

    // MARK: - Search Stores

    func searchStores(query: String, topK: Int = 20, minScore: Double = 0.3) -> (stores: [StoreWithCoordinates], storeProducts: [String: [ProductGraphQL]]) {
        guard let ctx = modelContext else { return ([], [:]) }

        var allBranches: [LocalBranch] = []
        var allProducts: [LocalProduct] = []

        do {
            allBranches = try ctx.fetch(FetchDescriptor<LocalBranch>())
            allProducts = try ctx.fetch(FetchDescriptor<LocalProduct>())
        } catch {
            print("❌ LocalSearchRepository - Error fetching branches: \(error)")
            return ([], [:])
        }

        let matchedBranches: [LocalBranch] = allBranches.compactMap { branch -> (LocalBranch, Double)? in
            let textScore = textMatch(query: query, text: "\(branch.name) \(branch.address ?? "")")
            var vectorScore = 0.0
            if let vec = branch.embedding {
                vectorScore = embeddingService.bestSimilarity(queryText: query, against: vec)
            }
            let finalScore = max(vectorScore, textScore)
            return finalScore >= minScore ? (branch, finalScore) : nil
        }
        .sorted { $0.1 > $1.1 }
        .prefix(topK)
        .map { $0.0 }

        // Agrupar productos por branch
        let productsByBranch = Dictionary(grouping: allProducts, by: { $0.branchId })

        var storeProducts: [String: [ProductGraphQL]] = [:]
        let stores = matchedBranches.map { branch -> StoreWithCoordinates in
            let branchProds = productsByBranch[branch.id]?.prefix(4).map { p in
                ProductGraphQL(
                    id: p.id,
                    branchId: p.branchId,
                    name: p.name,
                    price: p.price,
                    currency: p.currency,
                    imageUrl: p.imageUrl,
                    availability: p.availability,
                    createdAt: p.createdAt,
                    businessName: branch.name,
                    distanceKm: nil,
                    categoryId: p.categoryId,
                    categoryName: nil
                )
            } ?? []
            storeProducts[branch.id] = Array(branchProds)
            return mapToStore(branch)
        }

        return (stores, storeProducts)
    }

    // MARK: - Search Both

    func searchBoth(query: String, topK: Int = 10) -> LocalSearchResult {
        let products = searchProducts(query: query, topK: topK)
        let (stores, storeProds) = searchStores(query: query, topK: topK)
        return LocalSearchResult(products: products, stores: stores, storeProducts: storeProds)
    }

    // MARK: - Load Initial Data (sin búsqueda)

    func loadInitialProducts(limit: Int = 20) -> [Product] {
        guard let ctx = modelContext else { return [] }
        var descriptor = FetchDescriptor<LocalProduct>(
            predicate: #Predicate { $0.availability == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let products = (try? ctx.fetch(descriptor)) ?? []
        return products.map { mapToProduct($0) }
    }

    func loadInitialStores(limit: Int = 20) -> (stores: [StoreWithCoordinates], storeProducts: [String: [ProductGraphQL]]) {
        guard let ctx = modelContext else { return ([], [:]) }
        var descriptor = FetchDescriptor<LocalBranch>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        let branches = (try? ctx.fetch(descriptor)) ?? []
        let allProducts = (try? ctx.fetch(FetchDescriptor<LocalProduct>())) ?? []
        let productsByBranch = Dictionary(grouping: allProducts, by: { $0.branchId })

        var storeProducts: [String: [ProductGraphQL]] = [:]
        let stores = branches.map { branch -> StoreWithCoordinates in
            let branchProds = productsByBranch[branch.id]?.prefix(4).map { p in
                ProductGraphQL(
                    id: p.id,
                    branchId: p.branchId,
                    name: p.name,
                    price: p.price,
                    currency: p.currency,
                    imageUrl: p.imageUrl,
                    availability: p.availability,
                    createdAt: p.createdAt,
                    businessName: branch.name,
                    distanceKm: nil,
                    categoryId: p.categoryId,
                    categoryName: nil
                )
            } ?? []
            storeProducts[branch.id] = Array(branchProds)
            return mapToStore(branch)
        }

        return (stores, storeProducts)
    }

    // MARK: - Helpers

    private func textMatch(query: String, text: String) -> Double {
        let queryLower = query.lowercased()
        let textLower = text.lowercased()
        if textLower.contains(queryLower) { return 0.8 }
        // Búsqueda por palabras
        let words = queryLower.split(separator: " ")
        let matchCount = words.filter { textLower.contains($0) }.count
        return words.isEmpty ? 0 : Double(matchCount) / Double(words.count) * 0.6
    }

    private func mapToProduct(_ p: LocalProduct) -> Product {
        Product(
            id: p.id,
            name: p.name,
            shop: "",
            shopLogoUrl: "",
            weight: p.weight,
            price: p.formattedPrice,
            imageUrl: p.imageUrl
        )
    }

    private func mapToStore(_ branch: LocalBranch) -> StoreWithCoordinates {
        let eta = branch.deliveryRadius.map { Int($0 * 5 + 10) } ?? 20
        return StoreWithCoordinates(
            id: branch.id,
            name: branch.name,
            etaMinutes: eta,
            logoUrl: branch.avatarUrl ?? "",
            bannerUrl: branch.coverUrl ?? "",
            address: branch.address,
            rating: nil,
            description: nil,
            coordinate: CLLocationCoordinate2D(latitude: branch.latitude, longitude: branch.longitude)
        )
    }
}
