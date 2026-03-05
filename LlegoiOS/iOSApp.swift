import SwiftUI
import SwiftData
@preconcurrency import StripePaymentSheet

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let sharedModelContainer: ModelContainer?
    private let modelContainerErrorMessage: String?

    @MainActor
    init() {
        let schema = Schema([
            LocalBusiness.self,
            LocalBranch.self,
            LocalProduct.self,
            LocalImage.self,
            SyncMetadata.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
            self.modelContainerErrorMessage = nil
        } catch {
            self.sharedModelContainer = nil
            self.modelContainerErrorMessage =
                "No se pudo inicializar la base de datos local. Reinicia la app o reinstálala."
            print("❌ Error creando ModelContainer: \(error.localizedDescription)")
        }

        let key = "pk_test_FAKE_KEY_DO_NOT_USE_1234567890"
        StripeAPI.defaultPublishableKey = key

        _ = CartRecommendationsManager.shared

        // Limpiar caché de Apollo en cada inicio para evitar datos desactualizados
        ApolloClientManager.shared.clearDataCache()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let sharedModelContainer {
                    ContentView()
                        .modelContainer(sharedModelContainer)
                } else {
                    StartupErrorView(message: modelContainerErrorMessage ?? "Error de inicialización")
                }
            }
                .preferredColorScheme(.light) // Forzar modo claro en toda la app
                .onOpenURL { url in
                    let stripeHandled = StripeAPI.handleURLCallback(with: url)

                    if stripeHandled {
                        print("✅ Stripe manejó la URL: \(url)")
                    } else {
                        print("⚠️ URL no manejada por Stripe: \(url)")
                    }
                }
        }
    }
}

private struct StartupErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("No se pudo iniciar la app")
                .font(.system(size: 20, weight: .bold))

            Text(message)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
