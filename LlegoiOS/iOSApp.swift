import SwiftUI
import StripePaymentSheet

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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