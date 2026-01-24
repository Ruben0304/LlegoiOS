import Foundation
import Apollo

class AppUpdateRepository {
    private let apolloClient = ApolloClientManager.shared.apollo

    // MARK: - Fetch App Config
    func fetchAppConfig() async throws -> AppConfigData {
        return try await withCheckedThrowingContinuation { continuation in
            let query = LlegoAPI.GetAppConfigQuery()

            apolloClient.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
                switch result {
                case .success(let graphQLResult):
                    if let errors = graphQLResult.errors {
                        print("❌ GraphQL Errors (appConfig):")
                        errors.forEach { print("  - \($0.localizedDescription)") }
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: errors.first?.localizedDescription ?? "Error desconocido"]
                        ))
                        return
                    }

                    guard let data = graphQLResult.data?.appConfig else {
                        print("⚠️ appConfig devolvió nil")
                        continuation.resume(throwing: NSError(
                            domain: "GraphQL",
                            code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No se recibió configuración del servidor"]
                        ))
                        return
                    }

                    let appConfig = AppConfigData(
                        id: data.id,
                        minVersion: data.ios.minVersion,
                        currentVersion: data.ios.currentVersion,
                        storeUrl: data.ios.storeUrl,
                        maintenanceEnabled: data.maintenance.enabled,
                        maintenanceMessage: data.maintenance.message,
                        updateMessage: data.updateMessage,
                        changelog: data.changelog,
                        releaseDate: data.releaseDate
                    )

                    print("✅ AppConfig obtenido: minVersion=\(appConfig.minVersion), currentVersion=\(appConfig.currentVersion)")
                    continuation.resume(returning: appConfig)

                case .failure(let error):
                    print("❌ Error en fetchAppConfig: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Models
struct AppConfigData {
    let id: String
    let minVersion: String
    let currentVersion: String
    let storeUrl: String
    let maintenanceEnabled: Bool
    let maintenanceMessage: String?
    let updateMessage: String?
    let changelog: String?
    let releaseDate: String
}
