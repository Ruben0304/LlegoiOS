import SwiftUI

struct PlansAndPricingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var selectedPlan: PlanChoice = .yearly
    @State private var selectedCurrency: CurrencyChoice = .usd
    @State private var showPaymentSuccess = false
    @State private var showPaymentError = false

    enum PlanChoice {
        case yearly
        case monthly
    }

    enum CurrencyChoice: String, CaseIterable, Identifiable {
        case usd = "USD"
        case cup = "CUP"

        var id: String { rawValue }
    }

    private let features: [(title: String, detail: String)] = [
        ("IA más inteligente:", "Resultados precisos y recomendaciones personalizadas."),
        ("Compra asistida por IA:", "Cierra pedidos en menos pasos y con menos fricción."),
        ("Mensajería con ahorro:", "Gratis en rango local y rebaja en el resto."),
        ("Cashback en cada compra:", "Acumula saldo y úsalo en tus próximos pedidos.")
    ]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    headerSection

                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(features.indices, id: \.self) { index in
                            FeatureBulletRow(
                                title: features[index].title,
                                description: features[index].detail
                            )
                        }
                    }

                    planSelectionSection

                    Text("Cambia de plan o cancela cuando quieras.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.45))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    primaryCTA
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 44)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                CloseButton()
            }
        }
        .alert("¡Suscripción Exitosa! 🎉", isPresented: $showPaymentSuccess) {
            Button("Continuar", role: .cancel) {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Tu suscripción Premium ha sido activada. ¡Disfruta de envíos gratis!")
        }
        .alert("Error en el Pago", isPresented: $showPaymentError) {
            Button("Reintentar", role: .cancel) { }
        } message: {
            Text(paymentManager.lastError ?? "Hubo un problema procesando tu pago. Intenta nuevamente.")
        }
        .onAppear {
            print("🍎 Apple Pay Status: \(paymentManager.getApplePayStatus())")
        }
        .onChange(of: paymentManager.paymentStatus) { status in
            switch status {
            case .success:
                showPaymentSuccess = true
            case .failed:
                showPaymentError = true
            default:
                break
            }
        }
    }

    private var headerSection: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
            Text("Obtén Llego+\ny disfruta más.")
                .font(.custom("SF Pro Display", size: 32))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .lineSpacing(4)
                .padding(.top, 120)

            Text("Con Premium, llegas más rápido a tus objetivos.")
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .zIndex(1)

            Image("premium")
                .resizable()
                .scaledToFill()
                .frame(width: 240, height: 240)
                .clipped()
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
                .offset(x: 185, y: -48)
                .zIndex(0)
        }
    }

    private var planSelectionSection: some View {
        VStack(spacing: 22) {
            Text("Elige tu plan para la prueba gratis.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Picker("Moneda", selection: $selectedCurrency) {
                ForEach(CurrencyChoice.allCases) { currency in
                    Text(currency.rawValue).tag(currency)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .top, spacing: 16) {
                PlanOptionCard(
                    title: "ANUAL",
                    price: formattedPrice("68.98"),
                    priceUnit: "/AÑO",
                    originalPrice: "\(formattedPrice("179.76")) /AÑO",
                    billingText: "Se factura anualmente al terminar la prueba.",
                    savingsText: "62% AHORRO",
                    isSelected: selectedPlan == .yearly,
                    onSelect: { selectedPlan = .yearly }
                )

                PlanOptionCard(
                    title: "MENSUAL",
                    price: formattedPrice("14.98"),
                    priceUnit: "/MES",
                    originalPrice: nil,
                    billingText: "Se factura mensualmente al terminar la prueba.",
                    savingsText: nil,
                    isSelected: selectedPlan == .monthly,
                    onSelect: { selectedPlan = .monthly }
                )
            }
        }
    }

    private var primaryCTA: some View {
        Group {
            if #available(iOS 26, *) {
                Button(action: handleSubscription){
                    Text("Obtener Llegó plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .font(.system(size: 18, weight: .bold))
                }
                    .tint(Color.llegoPrimary)
                    .buttonStyle(.glassProminent)
//                    .controlSize(.extraLarge)
                    
            } else {
                Button(action: handleSubscription) {
                    Text("Obtener Llegó plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.llegoPrimary)
                        )
                }
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                
            }
        }
    }

    private func formattedPrice(_ amount: String) -> String {
        "\(selectedCurrency.rawValue) \(amount)"
    }

    private func handleSubscription() {
        paymentManager.processPayment(for: .premium) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Payment successful!")
                } else {
                    print("❌ Payment failed: \(error ?? "Unknown error")")
                    paymentManager.lastError = error
                }
            }
        }
    }
}


struct PlanOptionCard: View {
    let title: String
    let price: String
    let priceUnit: String
    let originalPrice: String?
    let billingText: String
    let savingsText: String?
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        Spacer(minLength: 0)

                        PlanSelectionIndicator(isSelected: isSelected)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(price)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)

                        Text(priceUnit)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.black.opacity(0.5))
                    }

                    if let originalPrice {
                        Text(originalPrice)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black.opacity(0.45))
                            .strikethrough()
                    }

                    Spacer(minLength: 0)

                    Text(billingText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.black.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .padding(.top, savingsText == nil ? 0 : 8)

                if let savingsText {
                    Text(savingsText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.55, blue: 0.33))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.76, green: 0.93, blue: 0.80))
                        )
                        .offset(x: 12, y: -12)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    NavigationStack {
        PlansAndPricingView()
    }
}
