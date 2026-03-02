//
//  RecommendationEngine.swift
//  LlegoiOS
//
//  Sistema de recomendaciones usando Apple Intelligence (FoundationModels)
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Motor de recomendaciones que usa Apple Intelligence en el dispositivo
@MainActor
final class RecommendationEngine {
    static let shared = RecommendationEngine()

    private init() {}

    /// Verifica si Apple Intelligence está disponible
    func isAvailable() -> Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            // Verificar disponibilidad del modelo del sistema
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return true
            case .unavailable:
                return false
            @unknown default:
                return false
            }
        }
        #endif
        return false
    }

    /// Obtiene recomendaciones de productos basadas en el carrito actual y el catálogo disponible
    /// - Parameters:
    ///   - cartItems: Nombres de productos en el carrito
    ///   - catalog: IDs y nombres de productos disponibles en el catálogo
    /// - Returns: Lista de IDs de productos recomendados
    func getRecommendations(
        cartItems: [String],
        catalog: [(id: String, name: String)]
    ) async throws -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            print("🔍 [RecommendationEngine] Iniciando generación de recomendaciones")
            print("🔍 [RecommendationEngine] Productos en carrito: \(cartItems.count)")
            print("🔍 [RecommendationEngine] Productos en catálogo: \(catalog.count)")

            // Verificar disponibilidad detallada
            let availabilityStatus = getAvailabilityStatus()
            print("🔍 [RecommendationEngine] Estado de disponibilidad: \(availabilityStatus.message)")

            guard isAvailable() else {
                print("❌ [RecommendationEngine] Apple Intelligence no disponible")
                throw RecommendationError.appleIntelligenceNotAvailable
            }

            print("✅ [RecommendationEngine] Apple Intelligence está disponible")

            // Limitar catálogo a 50 productos para no exceder el contexto
            let limitedCatalog = Array(catalog.prefix(50))
            print("🔍 [RecommendationEngine] Catálogo limitado a \(limitedCatalog.count) productos")

            // Construir el catálogo
            let catalogText = limitedCatalog.map { "ID: \($0.id), Nombre: \($0.name)" }.joined(separator: "\n")

            // Construir el prompt completo (system + user en un solo prompt)
            let prompt = """
            Eres un asistente experto en ventas cruzadas para un negocio en Cuba.
            Tu objetivo es recomendar productos complementarios basados en el carrito actual.
            Solo recomienda productos que existan en el catálogo proporcionado.

            IMPORTANTE:
            - Responde SOLO con los IDs de los productos recomendados, separados por comas.
            - No incluyas explicaciones, solo los IDs.
            - Ejemplo: "abc123,def456,ghi789"
            - Recomienda hasta 10 productos complementarios.
            - Prioriza productos que se compran JUNTOS con el carrito actual.
            - NO recomiendes productos sustitutos ni versiones muy similares de lo mismo.

            CARRITO ACTUAL:
            \(cartItems.joined(separator: ", "))

            CATÁLOGO DISPONIBLE:
            \(catalogText)

            ¿Qué productos del catálogo debería comprar el cliente para complementar su carrito?
            Responde solo con los IDs separados por comas.
            """

            let promptLength = prompt.count
            print("🔍 [RecommendationEngine] Longitud del prompt: \(promptLength) caracteres")

            // Crear sesión y generar respuesta
            print("🔍 [RecommendationEngine] Creando LanguageModelSession...")
            let session = LanguageModelSession()
            print("✅ [RecommendationEngine] Sesión creada")

            let response: LanguageModelSession.Response<String>

            do {
                print("🔍 [RecommendationEngine] Enviando prompt al modelo...")
                response = try await session.respond(to: prompt)
                print("✅ [RecommendationEngine] Respuesta recibida del modelo")
            } catch let error as NSError {
                print("❌ [RecommendationEngine] Error generando respuesta:")
                print("   - Domain: \(error.domain)")
                print("   - Code: \(error.code)")
                print("   - Description: \(error.localizedDescription)")
                print("   - UserInfo: \(error.userInfo)")

                // Detectar errores específicos
                var isModelManagerError1026 = false

                if let underlyingErrors = error.userInfo[NSMultipleUnderlyingErrorsKey] as? [Error] {
                    print("   - Underlying errors:")
                    for (index, underlyingError) in underlyingErrors.enumerated() {
                        let nsError = underlyingError as NSError
                        print("     [\(index)] Domain: \(nsError.domain), Code: \(nsError.code)")
                        print("     [\(index)] Description: \(nsError.localizedDescription)")

                        // Detectar ModelManagerError 1026
                        if nsError.domain == "ModelManagerServices.ModelManagerError" && nsError.code == 1026 {
                            isModelManagerError1026 = true
                        }
                    }
                }

                // Si es error 1026, lanzar un error más descriptivo
                if isModelManagerError1026 {
                    print("⚠️ [RecommendationEngine] Error 1026 detectado - Modelo no está listo")
                    print("💡 [RecommendationEngine] Soluciones:")
                    print("   1. Verifica que Apple Intelligence esté ACTIVADO en Configuración > Apple Intelligence")
                    print("   2. Asegúrate de tener iOS 26.0 beta o superior")
                    print("   3. El modelo puede estar descargándose. Espera unos minutos.")
                    print("   4. Prueba reiniciar la app y el dispositivo")
                    print("   5. Verifica que tengas un iPhone 15 Pro o superior")
                    throw RecommendationError.modelNotReady
                }

                throw error
            }

            // Extraer la respuesta
            let responseText = response.content
            print("🔍 [RecommendationEngine] Texto de respuesta: '\(responseText)'")
            print("🔍 [RecommendationEngine] Longitud de respuesta: \(responseText.count) caracteres")

            // Limpiar y extraer IDs
            let productIds = responseText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            print("✅ [RecommendationEngine] AI recomendó \(productIds.count) productos")
            print("🔍 [RecommendationEngine] IDs recomendados: \(productIds)")

            return productIds
        }
        #endif

        throw RecommendationError.appleIntelligenceNotAvailable
    }

    /// Obtiene el estado de disponibilidad con mensaje descriptivo
    func getAvailabilityStatus() -> (isAvailable: Bool, message: String) {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let availability = SystemLanguageModel.default.availability
            switch availability {
            case .available:
                return (true, "Apple Intelligence está disponible")
            case .unavailable(let reason):
                let reasonText = String(describing: reason)
                if reasonText.localizedCaseInsensitiveContains("deviceNotEligible") {
                    return (false, "Tu dispositivo no es compatible. Debe ser iPhone 15 Pro o superior.")
                }
                if reasonText.localizedCaseInsensitiveContains("appleIntelligenceNotEnabled") {
                    return (false, "Apple Intelligence está desactivado. Actívalo en Configuración.")
                }
                return (false, "Apple Intelligence no disponible: \(reasonText)")
            @unknown default:
                return (false, "Estado desconocido de Apple Intelligence")
            }
        }
        #endif
        return (false, "Apple Intelligence requiere iOS 26.0 o superior")
    }
    
    func reRankSimilar(
        productName: String,
        candidates: [(id: String, name: String)]
    ) async throws -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            print("🔍 [RecommendationEngine] Re-ranking similares")
            print("🔍 [RecommendationEngine] Producto: \(productName)")
            print("🔍 [RecommendationEngine] Candidatos: \(candidates.count)")

            guard isAvailable() else {
                throw RecommendationError.appleIntelligenceNotAvailable
            }

            var activeCandidates = candidates
            var attempt = 1

            while !activeCandidates.isEmpty {
                if attempt > 1 {
                    print("⚠️ [RecommendationEngine] Reintento \(attempt) con \(activeCandidates.count) candidatos (reducción aleatoria)")
                }

                let indexToId: [String: String] = Dictionary(
                    uniqueKeysWithValues: activeCandidates.enumerated().map { ("\($0.offset + 1)", $0.element.id) }
                )

                let candidatesText = Self.buildCandidatesText(activeCandidates)

                let prompt = """
                Eres un experto en recomendaciones de productos.
                Reordena los siguientes candidatos por similitud al producto de referencia.
                
                PRODUCTO DE REFERENCIA:
                \(productName)
                
                CANDIDATOS:
                \(candidatesText)
                
                INSTRUCCIONES:
                - Responde SOLO con los números de los candidatos reordenados, separados por comas
                - Ordena del MÁS similar al MENOS similar
                - NO incluyas el producto de referencia
                - Devuelve como máximo 10 números
                - Ejemplo: "3,1,5,2"
                
                Números reordenados:
                """

                print("🔍 [RecommendationEngine] Intento \(attempt): \(activeCandidates.count) candidatos, \(prompt.count) chars (~\(prompt.count / 4) tokens)")

                do {
                    let session = LanguageModelSession()
                    let response = try await session.respond(to: prompt)

                    let returnedIndexes = response.content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    let productIds = returnedIndexes.compactMap { indexToId[$0] }

                    guard !productIds.isEmpty else {
                        throw RecommendationError.invalidResponse
                    }

                    let validCandidateIds = Set(activeCandidates.map { $0.id })
                    let validatedIds = productIds.filter { validCandidateIds.contains($0) }
                    let uniqueIds = Array(NSOrderedSet(array: validatedIds)) as! [String]
                    let limitedIds = uniqueIds

                    if attempt > 1 {
                        print("✅ [RecommendationEngine] Éxito en intento \(attempt) con \(activeCandidates.count) candidatos")
                    }
                    print("✅ [RecommendationEngine] Re-ranking completado: \(limitedIds.count) productos")
                    return limitedIds

                } catch {
                    let isContextOverflow: Bool
                    if #available(iOS 26.0, *) {
                        if case LanguageModelSession.GenerationError.exceededContextWindowSize = error {
                            isContextOverflow = true
                        } else {
                            isContextOverflow = false
                        }
                    } else {
                        isContextOverflow = error.localizedDescription.localizedCaseInsensitiveContains("context window")
                    }

                    guard isContextOverflow, activeCandidates.count > 10 else {
                        print("❌ [RecommendationEngine] Error no recuperable: \(error.localizedDescription)")
                        throw error
                    }

                    let removeCount = min(10, activeCandidates.count - 10)
                    let shuffledIndexes = Array(0..<activeCandidates.count).shuffled()
                    let toRemove = Set(shuffledIndexes.prefix(removeCount))
                    activeCandidates = activeCandidates.enumerated()
                        .filter { !toRemove.contains($0.offset) }
                        .map { $0.element }

                    print("⚠️ [RecommendationEngine] Context overflow en intento \(attempt) — reduciendo a \(activeCandidates.count) candidatos (eliminados \(removeCount) aleatorios)")
                    attempt += 1
                }
            }

            throw RecommendationError.catalogEmpty
        }
        #endif

        throw RecommendationError.appleIntelligenceNotAvailable
    }
    
    func reRankComplementary(
        cartNames: [String],
        candidates: [(id: String, name: String)]
    ) async throws -> [String] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            print("🔍 [RecommendationEngine] Re-ranking complementarios")
            print("🔍 [RecommendationEngine] Carrito: \(cartNames)")
            print("🔍 [RecommendationEngine] Candidatos: \(candidates.count)")

            guard isAvailable() else {
                throw RecommendationError.appleIntelligenceNotAvailable
            }

            // Retry loop: start with all candidates, reduce by 10 randomly on each context overflow.
            var activeCandidates = candidates
            var attempt = 1

            while !activeCandidates.isEmpty {
                if attempt > 1 {
                    print("⚠️ [RecommendationEngine] Reintento \(attempt) con \(activeCandidates.count) candidatos (reducción aleatoria)")
                }

                // Rebuild index map for current candidate set
                let indexToId: [String: String] = Dictionary(
                    uniqueKeysWithValues: activeCandidates.enumerated().map { ("\($0.offset + 1)", $0.element.id) }
                )

                let candidatesText = Self.buildCandidatesText(activeCandidates)
                let cartText = cartNames.joined(separator: ", ")

                let prompt = """
                Eres un experto en ventas cruzadas.
                Reordena los siguientes candidatos por complementariedad con el carrito actual.
                
                CARRITO ACTUAL:
                \(cartText)
                
                CANDIDATOS:
                \(candidatesText)
                
                INSTRUCCIONES:
                - Responde SOLO con los números de los candidatos reordenados, separados por comas
                - Ordena del MÁS complementario al MENOS complementario
                - Prioriza productos que se compran JUNTOS con el carrito actual
                - NO recomiendes sustitutos ni productos que sean esencialmente lo mismo
                - Devuelve como máximo 10 números
                - Ejemplo: "3,1,5,2"
                
                Números reordenados:
                """

                print("🔍 [RecommendationEngine] Intento \(attempt): \(activeCandidates.count) candidatos, \(prompt.count) chars (~\(prompt.count / 4) tokens)")

                do {
                    let session = LanguageModelSession()
                    let response = try await session.respond(to: prompt)

                    // Map numeric indexes back to real IDs
                    let returnedIndexes = response.content
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }

                    let productIds = returnedIndexes.compactMap { indexToId[$0] }

                    guard !productIds.isEmpty else {
                        throw RecommendationError.invalidResponse
                    }

                    let validCandidateIds = Set(activeCandidates.map { $0.id })
                    let validatedIds = productIds.filter { validCandidateIds.contains($0) }
                    let uniqueIds = Array(NSOrderedSet(array: validatedIds)) as! [String]
                    let limitedIds = uniqueIds

                    if attempt > 1 {
                        print("✅ [RecommendationEngine] Éxito en intento \(attempt) con \(activeCandidates.count) candidatos")
                    }
                    print("✅ [RecommendationEngine] Re-ranking completado: \(limitedIds.count) productos")
                    return limitedIds

                } catch {
                    // Check if it's a context window overflow — if so, reduce randomly and retry
                    let isContextOverflow: Bool
                    if #available(iOS 26.0, *) {
                        if case LanguageModelSession.GenerationError.exceededContextWindowSize = error {
                            isContextOverflow = true
                        } else {
                            isContextOverflow = false
                        }
                    } else {
                        isContextOverflow = error.localizedDescription.localizedCaseInsensitiveContains("context window")
                    }

                    guard isContextOverflow, activeCandidates.count > 10 else {
                        print("❌ [RecommendationEngine] Error no recuperable: \(error.localizedDescription)")
                        throw error
                    }

                    // Remove 10 random candidates (shuffled to avoid always cutting from the same category)
                    let removeCount = min(10, activeCandidates.count - 10)
                    let shuffledIndexes = Array(0..<activeCandidates.count).shuffled()
                    let toRemove = Set(shuffledIndexes.prefix(removeCount))
                    activeCandidates = activeCandidates.enumerated()
                        .filter { !toRemove.contains($0.offset) }
                        .map { $0.element }

                    print("⚠️ [RecommendationEngine] Context overflow en intento \(attempt) — reduciendo a \(activeCandidates.count) candidatos (eliminados \(removeCount) aleatorios)")
                    attempt += 1
                }
            }

            throw RecommendationError.catalogEmpty
        }
        #endif

        throw RecommendationError.appleIntelligenceNotAvailable
    }

    /// Builds a compact candidate list that fits within the model's context window.
    ///
    /// Strategy:
    /// - Context window: 4,096 tokens ≈ 12,000 chars (Spanish ~3 chars/token)
    /// - Budget for candidates: 12,000 - 800 (prompt boilerplate + cart + response) = 11,200 chars
    /// - Each line: "N: <name>\n" → fixed overhead ≈ 5 chars (index + ": " + "\n")
    /// - Available per product for name text: floor(11,200 / count) - 5
    /// - Names are truncated uniformly to that budget. No prices are included.
    private static func buildCandidatesText(_ candidates: [(id: String, name: String)]) -> String {
        let count = max(1, candidates.count)
        let totalBudget = 11_200
        let fixedOverheadPerLine = 5  // "N: " + "\n" (up to 2-digit index)
        let charsPerProduct = max(10, (totalBudget / count) - fixedOverheadPerLine)

        return candidates.enumerated().map { i, c in
            let name = c.name.count > charsPerProduct ? String(c.name.prefix(charsPerProduct)) : c.name
            return "\(i + 1): \(name)"
        }.joined(separator: "\n")
    }
}

/// Errores del motor de recomendaciones
enum RecommendationError: LocalizedError {
    case appleIntelligenceNotAvailable
    case invalidResponse
    case catalogEmpty
    case cartEmpty
    case modelNotReady
    case entitlementMissing

    var errorDescription: String? {
        switch self {
        case .appleIntelligenceNotAvailable:
            return "Apple Intelligence no está disponible en este dispositivo"
        case .invalidResponse:
            return "No se pudo interpretar la respuesta del modelo"
        case .catalogEmpty:
            return "El catálogo de productos está vacío"
        case .cartEmpty:
            return "El carrito está vacío"
        case .modelNotReady:
            return """
            El modelo de Apple Intelligence no está listo. Posibles soluciones:
            1. Verifica que Apple Intelligence esté activado en Configuración
            2. Asegúrate de estar en iOS 26.0 beta o superior
            3. El modelo puede estar descargándose en segundo plano
            4. Reinicia la app y el dispositivo
            """
        case .entitlementMissing:
            return "Falta el entitlement de Foundation Models. Recompila la app."
        }
    }
}
