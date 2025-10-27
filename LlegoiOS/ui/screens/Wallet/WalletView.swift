import SwiftUI
import PassKit

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = 0

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.llegoPrimary.opacity(0.1),
                    Color.llegoBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Main Balance Card (estilo wallet moderna)
                    ZStack {
                        // Card Background con gradiente
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.llegoPrimary,
                                        Color.llegoPrimary.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                        // Decorative circles (estilo Apple Card)
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .offset(x: 100, y: -80)
                            .blur(radius: 20)

                        Circle()
                            .fill(Color.llegoSecondary.opacity(0.2))
                            .frame(width: 150, height: 150)
                            .offset(x: -80, y: 100)
                            .blur(radius: 15)

                        // Card Content
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Llego Wallet")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.9))

                                    Text("Balance disponible")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                // Wallet Icon
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.llegoSecondary)
                            }

                            Spacer()

                            // Balance Amount
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("$")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text(String(format: "%.2f", viewModel.balance))
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("USD")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }

                            // Card Number Decoration (opcional, estilo tarjeta)
                            HStack(spacing: 12) {
                                ForEach(0..<4) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                }

                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)

                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)

                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)

                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)

                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                    }
                    .frame(height: 220)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .rotation3DEffect(
                        .degrees(cardRotation),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(x: cardOffset)

                    // Quick Actions Grid
                    VStack(spacing: 16) {
                        Text("Acciones rápidas")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        HStack(spacing: 12) {
                            // Recargar Action
                            Button(action: {
                                viewModel.showRechargeSheet = true
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.llegoPrimary.opacity(0.15))
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.llegoPrimary)
                                    }

                                    Text("Recargar")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Recargar Internacional Action
                            Button(action: {
                                viewModel.generateForeignRechargeURL()
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.llegoAccent.opacity(0.15))
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "globe.americas.fill")
                                            .font(.system(size: 28))
                                            .foregroundColor(.llegoAccent)
                                    }

                                    Text("Internacional")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)

                        // Additional Actions Row
                        HStack(spacing: 12) {
                            // Transferir Action
                            Button(action: {
                                // TODO: Implementar transferencia
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.llegoSecondary.opacity(0.15))
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "arrow.left.arrow.right")
                                            .font(.system(size: 24))
                                            .foregroundColor(.llegoTertiary)
                                    }

                                    Text("Transferir")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Historial Action
                            Button(action: {
                                // TODO: Implementar historial
                            }) {
                                VStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.15))
                                            .frame(width: 56, height: 56)

                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gray)
                                    }

                                    Text("Historial")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 20)
                    }

                    // Info Cards
                    VStack(spacing: 12) {
                        // Apple Pay Info
                        HStack(spacing: 12) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 24))
                                .foregroundColor(.black)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Paga con Apple Pay")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Seguro, rápido y privado")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        )

                        // Security Info
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.llegoPrimary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Transacciones seguras")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("Protección bancaria nivel 256-bit")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }

            // Success Message Overlay
            if viewModel.showSuccessMessage {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)

                        Text(viewModel.successMessage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.showSuccessMessage)
            }
        }
        .navigationTitle("Mi Wallet")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseButton(action: {
                    dismiss()
                })
            }
        }
        .sheet(isPresented: $viewModel.showRechargeSheet) {
            LocalRechargeSheet(viewModel: viewModel)
                .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $viewModel.showForeignRechargeSheet) {
            ForeignRechargeSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .onAppear {
            viewModel.loadBalance()
        }
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Local Recharge Sheet
struct LocalRechargeSheet: View {
    @ObservedObject var viewModel: WalletViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Amount Input
                VStack(spacing: 8) {
                    Text("Monto a recargar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)

                        TextField("0.00", text: $viewModel.rechargeAmount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .focused($isAmountFocused)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal)

                // Quick amount buttons
                HStack(spacing: 12) {
                    ForEach([10.0, 25.0, 50.0, 100.0], id: \.self) { amount in
                        Button(action: {
                            viewModel.rechargeAmount = String(format: "%.0f", amount)
                        }) {
                            Text("$\(Int(amount))")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.llegoPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.llegoPrimary.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Apple Pay Button
                if let amount = Double(viewModel.rechargeAmount), amount > 0 {
                    Button(action: {
                        viewModel.processLocalRecharge()
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Pagar con Apple Pay")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Recargar Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isAmountFocused = true
            }
        }
    }
}

// MARK: - Foreign Recharge Sheet
struct ForeignRechargeSheet: View {
    @ObservedObject var viewModel: WalletViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.llegoAccent)
                    .padding(.bottom, 8)

                // Title
                Text("Recarga desde el extranjero")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)

                // Description
                Text("Comparte este enlace con alguien en el extranjero para que pueda enviarte dinero a tu Wallet")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // URL Card
                VStack(spacing: 16) {
                    Text(viewModel.foreignRechargeURL)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.llegoPrimary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.llegoPrimary.opacity(0.1))
                        )

                    // Copy button
                    Button(action: {
                        viewModel.copyURLToClipboard()
                        showCopiedConfirmation = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopiedConfirmation = false
                        }
                    }) {
                        HStack {
                            Image(systemName: showCopiedConfirmation ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                .font(.system(size: 18))
                            Text(showCopiedConfirmation ? "¡Copiado!" : "Copiar enlace")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(showCopiedConfirmation ? Color.green : Color.llegoPrimary)
                        )
                    }
                    .animation(.spring(response: 0.3), value: showCopiedConfirmation)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Recarga Internacional")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        WalletView()
    }
}
