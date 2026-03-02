import SwiftUI
import SwiftData
@preconcurrency import StripePaymentSheet

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LocalBusiness.self,
            LocalBranch.self,
            LocalProduct.self,
            LocalImage.self,
            SyncMetadata.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()

    @MainActor
    init() {
        // Inicializar Stripe con la publishable key
        // El warning de concurrencia es un falso positivo - solo se ejecuta una vez al inicio
        let key = "pk_live_51SaOijR1ZUqDQNdsxozHByR3YnLCmBn6yegicHThwyfzAJRJadg5o4pZEB6pwuaFaJr7LPFbqmpDagwUdfdGzRg200S9EKBDYL"
        StripeAPI.defaultPublishableKey = key

        // Inicializa el manager global de recomendaciones para escuchar cambios del carrito.
        _ = CartRecommendationsManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(.light) // Forzar modo claro en toda la app
                .onOpenURL { url in
                    // Manejar URLs de Stripe para autenticación
                    let stripeHandled = StripeAPI.handleURLCallback(with: url)

                    if stripeHandled {
                        print("✅ Stripe manejó la URL: \(url)")
                    } else {
                        print("⚠️ URL no manejada por Stripe: \(url)")
                        // Aquí puedes manejar otras URLs personalizadas
                    }
                }
        }
    }
}
