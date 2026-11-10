import SwiftUI
import SwiftData
import Foundation
import os

@main
struct iOSApp: App {
    static var isTestMode: Bool {
        ProcessInfo.processInfo.environment["LLEGO_TEST_MODE"] == "1"
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let sharedModelContainer: ModelContainer?
    private let modelContainerErrorMessage: String?

    @MainActor
    init() {
        if Self.isTestMode {
            self.sharedModelContainer = nil
            self.modelContainerErrorMessage = nil
            return
        }
        let schema = Schema([
            LocalBusiness.self,
            LocalBranch.self,
            LocalProduct.self,
            LocalImage.self,
            SyncMetadata.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            self.sharedModelContainer = container
            self.modelContainerErrorMessage = nil

            // Los datos offline deben estar disponibles desde el arranque, no solo
            // cuando se abre la pantalla de búsqueda: las pantallas de detalle
            // (producto/tienda) también leen de aquí cuando no hay red.
            OfflineSyncService.shared.configure(modelContext: container.mainContext)
            OfflineDetailRepository.shared.configure(modelContext: container.mainContext)
        } catch {
            self.sharedModelContainer = nil
            self.modelContainerErrorMessage =
                "No se pudo inicializar la base de datos local. Reinicia la app o reinstálala."
            print("❌ Error creando ModelContainer: \(error.localizedDescription)")
        }

        _ = CartRecommendationsManager.shared

        // Iniciar GPS silenciosamente desde el arranque.
        // Si no llega antes de renderizar Home, se usa La Habana como fallback.
        UserLocationManager.shared.startAutoLocation()

        // Limpiar caché de Apollo en cada inicio para evitar datos desactualizados
        ApolloClientManager.shared.clearDataCache()

        Task {
            await ServerClock.shared.sync()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.isTestMode {
                    Color.clear
                } else if let sharedModelContainer {
                    ContentView()
                        .modelContainer(sharedModelContainer)
                } else {
                    StartupErrorView(message: modelContainerErrorMessage ?? "Error de inicialización")
                }
            }
                .preferredColorScheme(.light) // Forzar modo claro en toda la app
        }
    }
}

private struct StartupErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .scaledFont(size: 40, relativeTo: .largeTitle)
                .foregroundColor(.orange)

            Text("No se pudo iniciar la app")
                .scaledFont(size: 20, weight: .bold, relativeTo: .title3)

            Text(message)
                .scaledFont(size: 15, relativeTo: .subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
