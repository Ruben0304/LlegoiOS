import SwiftUI
import StripePaymentSheet

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
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