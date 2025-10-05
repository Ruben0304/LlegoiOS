import SwiftUI
import PassKit

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    VStack(spacing: 12) {
                        Text("Balance disponible")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(String(format: "%.2f", viewModel.balance))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Text("USD")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Action Buttons
                    VStack(spacing: 12) {
                        // Recargar button
                        Button(action: {
                            viewModel.showRechargeSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Recargar")
                                    .font(.system(size: 17, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.llegoPrimary)
                            )
                        }

                        // Recargar desde el extranjero button
                        Button(action: {
                            viewModel.generateForeignRechargeURL()
                        }) {
                            HStack {
                                Image(systemName: "globe.americas.fill")
                                    .font(.system(size: 20))
                                Text("Recargar desde el extranjero")
                                    .font(.system(size: 17, weight: .semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.llegoAccent)
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }

            // Success Message Overlay
            if viewModel.showSuccessMessage {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(viewModel.successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding()

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
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $viewModel.showRechargeSheet) {
            LocalRechargeSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showForeignRechargeSheet) {
            ForeignRechargeSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadBalance()
        }
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
