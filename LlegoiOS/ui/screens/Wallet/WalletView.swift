import SwiftUI
import PassKit
import StripePaymentSheet

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCurrency: WalletCurrency = .usd
    @State private var animateContent: Bool = false
    @State private var showCupTransferSheet: Bool = false
    var body: some View {
        NavigationStack{
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
                        // Main Balance Cards
                        VStack(spacing: 14) {
                            TabView(selection: $selectedCurrency) {
                                ForEach(WalletCurrency.allCases) { currency in
                                    WalletAccountCard(
                                        currency: currency,
                                        amount: viewModel.balance(for: currency),
                                        onReimburseTap: currency == .cup ? {
                                            viewModel.showRefundSheet = true
                                        } : nil
                                    )
                                    .tag(currency)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                }
                            }
                            .frame(height: 240)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selectedCurrency)
                            
                            HStack(spacing: 12) {
                                ForEach(WalletCurrency.allCases) { currency in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                            selectedCurrency = currency
                                        }
                                    }) {
                                        Text(currency.switcherTitle)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(selectedCurrency == currency ? .white : .primary.opacity(0.7))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        selectedCurrency == currency ?
                                                        currency.activeColor :
                                                            Color(.systemGray6)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 24)
                        .animation(.easeOut(duration: 0.55).delay(0.05), value: animateContent)
                        
                        // Quick Actions Grid
                        VStack(spacing: 16) {
                            HStack {
                                Text("Acciones rápidas")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(selectedCurrency.currencyCode)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            
                            HStack(spacing: 12) {
                                // Recargar Action
                                Button(action: {
                                    viewModel.rechargeAmount = ""
                                    if selectedCurrency == .cup {
                                        selectedCurrency = .cup
                                    }
                                    viewModel.showRechargeSheet = true
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedCurrency.activeColor.opacity(0.15))
                                                .frame(width: 56, height: 56)
                                            
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(selectedCurrency.activeColor)
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
                                            
                                            if viewModel.isGeneratingForeignURL {
                                                ProgressView()
                                                    .tint(.llegoAccent)
                                            } else {
                                                Image(systemName: "globe.americas.fill")
                                                    .font(.system(size: 28))
                                                    .foregroundColor(.llegoAccent)
                                            }
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
                                .disabled(viewModel.isGeneratingForeignURL)
                            }
                            .padding(.horizontal, 20)
                            
                            // Additional Actions Row
                            HStack(spacing: 12) {
                                // Transferir Action
                                Button(action: {
                                    viewModel.presentTransferSheet()
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
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 24)
                        .animation(.easeOut(duration: 0.55).delay(0.15), value: animateContent)
                        
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
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 16)
                        .animation(.easeOut(duration: 0.55).delay(0.25), value: animateContent)

                        // Loading Indicator for Transactions
                        if viewModel.isLoadingTransactions {
                            VStack(spacing: 16) {
                                CircularLoadingIndicator(
                                    color: .llegoPrimary,
                                    lineWidth: 4,
                                    size: 40,
                                    useHDR: true
                                )

                                Text("Cargando transacciones...")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 20)
                        } else {
                            // Transaction History
                            TransactionHistoryView(
                                transactions: viewModel.transactions,
                                currentUserId: viewModel.currentUserId
                            )
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 16)
                            .animation(.easeOut(duration: 0.55).delay(0.35), value: animateContent)
                        }

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
                LocalRechargeSheet(
                    viewModel: viewModel,
                    selectedCurrency: $selectedCurrency,
                    onCupTransferTap: { amountText in
                        viewModel.prepareCupTransfer(amountText: amountText)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showCupTransferSheet = true
                        }
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showForeignRechargeSheet) {
                ForeignRechargeSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $viewModel.showTransferSheet) {
                WalletTransferSheet(
                    viewModel: viewModel,
                    selectedCurrency: selectedCurrency
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCupTransferSheet) {
                BankTransferSheetView(
                    totalAmount: viewModel.cupTransferAmountDisplay,
                    allowAmountEditing: true,
                    onConfirm: { amountText in
                        viewModel.completeCupTransferRecharge(amountString: amountText)
                        showCupTransferSheet = false
                    },
                    onDismiss: {
                        showCupTransferSheet = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showRefundSheet) {
                RefundInfoSheet(currency: .cup)
                    .presentationDetents([.height(260)])
            }
            .background(
                StripePaymentSheetPresenter(
                    isPresented: $viewModel.showStripePaymentSheet,
                    paymentSheet: viewModel.paymentSheet,
                    onCompletion: viewModel.handleStripePaymentResult
                )
            )
            .onAppear {
                animateContent = false
                DispatchQueue.main.async {
                    animateContent = true
                }
                // Cargar balance y transacciones
                viewModel.loadWalletDetails()
            }
            .onDisappear {
                animateContent = false
            }
        }
    }
}

// MARK: - Wallet Account Card
private struct WalletAccountCard: View {
    let currency: WalletCurrency
    let amount: Double
    var onReimburseTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 24)
                .fill(currency.cardGradient)
                .shadow(color: currency.shadowColor, radius: 20, x: 0, y: 12)

            Circle()
                .fill(currency.primaryDecorationColor)
                .frame(width: 200, height: 200)
                .offset(x: 110, y: -90)
                .blur(radius: 20)

            Circle()
                .fill(currency.secondaryDecorationColor)
                .frame(width: 150, height: 150)
                .offset(x: -90, y: 110)
                .blur(radius: 15)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Llego Wallet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text(currency.cardSubtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currency.accentIconColor)
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(currency.symbol)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(String(format: "%.2f", amount))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    Text(currency.currencyCode)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                        )
                }

                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(Color.white.opacity(index.isMultiple(of: 2) ? 0.35 : 0.25))
                            .frame(width: 8, height: 8)
                    }

                    Spacer()
                }
                .padding(.top, 8)
            }
            .padding(24)

            if let onReimburseTap, currency == .cup {
                Button(action: onReimburseTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 18))
                        Text("Reembolsar")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                    )
                }
                .buttonStyle(.plain)
                .padding(24)
            }
        }
        .frame(height: 220)
    }
}

private extension WalletCurrency {
    var cardGradient: LinearGradient {
        switch self {
        case .usd:
            return LinearGradient(
                colors: [Color.llegoPrimary, Color.llegoPrimary.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .cup:
            return LinearGradient(
                colors: [Color.llegoTertiary, Color.llegoTertiary.opacity(0.82)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var cardSubtitle: String {
        switch self {
        case .usd:
            return "Balance disponible"
        case .cup:
            return "Saldo en CUP"
        }
    }

    var accentIconColor: Color {
        switch self {
        case .usd:
            return .llegoSecondary
        case .cup:
            return .llegoSecondary
        }
    }

    var activeColor: Color {
        switch self {
        case .usd:
            return .llegoPrimary
        case .cup:
            return .llegoTertiary
        }
    }

    var switcherTitle: String {
        switch self {
        case .usd:
            return "Cuenta USD"
        case .cup:
            return "Cuenta CUP"
        }
    }

    var primaryDecorationColor: Color {
        switch self {
        case .usd:
            return Color.white.opacity(0.12)
        case .cup:
            return Color.llegoSecondary.opacity(0.28)
        }
    }

    var secondaryDecorationColor: Color {
        switch self {
        case .usd:
            return Color.llegoSecondary.opacity(0.18)
        case .cup:
            return Color.llegoAccent.opacity(0.18)
        }
    }

    var shadowColor: Color {
        switch self {
        case .usd:
            return Color.llegoPrimary.opacity(0.3)
        case .cup:
            return Color.llegoTertiary.opacity(0.32)
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
    @Binding var selectedCurrency: WalletCurrency
    var onCupTransferTap: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAmountFocused: Bool
    @State private var showDiagnostics = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Currency Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Moneda")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("Moneda", selection: $selectedCurrency) {
                            ForEach(WalletCurrency.allCases) { currency in
                                Text(currency.currencyCode)
                                    .tag(currency)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Amount Input
                    VStack(spacing: 8) {
                        Text("Monto a recargar")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(selectedCurrency.symbol)
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
                                Text("\(selectedCurrency.symbol)\(Int(amount))")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedCurrency.activeColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedCurrency.activeColor.opacity(0.12))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Payment Buttons
                    let sanitizedAmount = viewModel.rechargeAmount.replacingOccurrences(of: ",", with: ".")
                    if let amount = Double(sanitizedAmount), amount > 0 {
                        VStack(spacing: 12) {
                            if selectedCurrency == .usd {
                                // Apple Pay Button
                                Button(action: {
                                    viewModel.rechargeAmount = sanitizedAmount
                                    viewModel.processApplePayRecharge(for: selectedCurrency)
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

                                // Stripe Button (Deshabilitado - Próximamente)
                                Button(action: {
                                    // No hacer nada - botón deshabilitado
                                }) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 18))
                                        Text("Stripe próximamente")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.gray.opacity(0.4))
                                    )
                                }
                                .disabled(true)

                                // Manual Test Button
                                Button(action: {
                                    viewModel.rechargeAmount = sanitizedAmount
                                    viewModel.processManualRecharge(for: selectedCurrency)
                                }) {
                                    HStack {
                                        Image(systemName: "testtube.2")
                                            .font(.system(size: 18))
                                        Text("Recarga Manual (Prueba)")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.llegoAccent)
                                    )
                                }
                            } else {
                                // Info: Stripe no soporta CUP
                                HStack(spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Solo transferencia bancaria")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text("Los pagos con tarjeta solo están disponibles para USD")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .padding(.horizontal)
                                
                                // CUP Transfer Button
                                Button(action: {
                                    let amountText = sanitizedAmount
                                    viewModel.rechargeAmount = amountText
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        onCupTransferTap(amountText)
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "building.columns.fill")
                                            .font(.system(size: 18))
                                        Text("Continuar con transferencia CUP")
                                            .font(.system(size: 16, weight: .semibold))
                                            .lineLimit(1)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        selectedCurrency.activeColor,
                                                        selectedCurrency.activeColor.opacity(0.8)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                                .padding(.horizontal)

                                // Manual Test Button for CUP
                                Button(action: {
                                    viewModel.rechargeAmount = sanitizedAmount
                                    viewModel.processManualRecharge(for: selectedCurrency)
                                }) {
                                    HStack {
                                        Image(systemName: "testtube.2")
                                            .font(.system(size: 18))
                                        Text("Recarga Manual (Prueba)")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.llegoAccent)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
            .navigationTitle("Recargar Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showDiagnostics = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .alert("Diagnóstico Apple Pay", isPresented: $showDiagnostics) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.getApplePayDiagnostics())
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
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.llegoAccent.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.llegoAccent)
                    }
                    .padding(.top, 20)

                    // Title
                    Text("Recarga desde el extranjero")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.primary)

                    // Description
                    VStack(spacing: 12) {
                        Text("Comparte este enlace con familiares o amigos en el extranjero")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Ellos podrán enviarte dinero directamente a tu Wallet usando su tarjeta internacional")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    // URL Card
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tu enlace de recarga")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            Text(viewModel.foreignRechargeURL)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.llegoPrimary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.llegoPrimary.opacity(0.08))
                                )
                                .lineLimit(3)
                        }

                        // Copy button
                        Button(action: {
                            viewModel.copyURLToClipboard()
                            showCopiedConfirmation = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedConfirmation = false
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: showCopiedConfirmation ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                    .font(.system(size: 18, weight: .semibold))
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
                        
                        // Share button
                        ShareLink(item: viewModel.foreignRechargeURL) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Compartir enlace")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.llegoPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.llegoPrimary.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    // Info cards
                    VStack(spacing: 12) {
                        InfoCard(
                            icon: "creditcard.fill",
                            title: "Pago seguro",
                            description: "Stripe próximamente disponible"
                        )
                        
                        InfoCard(
                            icon: "dollarsign.circle.fill",
                            title: "Ellos eligen el monto",
                            description: "La persona que paga decide cuánto enviarte"
                        )
                        
                        InfoCard(
                            icon: "clock.fill",
                            title: "Acreditación inmediata",
                            description: "El dinero llega a tu Wallet en segundos"
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
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

// MARK: - Info Card
private struct InfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.llegoAccent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Wallet Transfer Sheet
struct WalletTransferSheet: View {
    @ObservedObject var viewModel: WalletViewModel
    let selectedCurrency: WalletCurrency
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private let quickAmounts: [Double] = [10, 25, 50, 100]

    private enum Field {
        case username
        case amount
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(selectedCurrency.activeColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(selectedCurrency.activeColor)
                        }

                        Text("Transferir saldo")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Envía dinero a otro usuario de Llego usando su nombre de usuario o correo electrónico.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Usuario o correo destino")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("ej. juan.perez o correo@ejemplo.com", text: $viewModel.transferUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .focused($focusedField, equals: .username)
                                .onChange(of: viewModel.transferUsername) { _, newValue in
                                    viewModel.searchUsers(query: newValue)
                                }
                            
                            // Search Results
                            if !viewModel.searchResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.searchResults, id: \.id) { user in
                                        Button(action: {
                                            viewModel.selectUser(user)
                                            focusedField = .amount
                                        }) {
                                            HStack(spacing: 12) {
                                                // Avatar
                                                if let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty {
                                                    AsyncImage(url: URL(string: avatarUrl)) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image
                                                                .resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 40, height: 40)
                                                                .clipShape(Circle())
                                                        default:
                                                            Circle()
                                                                .fill(Color.gray.opacity(0.2))
                                                                .frame(width: 40, height: 40)
                                                                .overlay(
                                                                    Image(systemName: "person.fill")
                                                                        .font(.system(size: 18))
                                                                        .foregroundColor(.gray)
                                                                )
                                                        }
                                                    }
                                                } else {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.2))
                                                        .frame(width: 40, height: 40)
                                                        .overlay(
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 18))
                                                                .foregroundColor(.gray)
                                                        )
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(user.name)
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    
                                                    Text("@\(user.username)")
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.gray.opacity(0.5))
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemBackground))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        if user.id != viewModel.searchResults.last?.id {
                                            Divider()
                                                .padding(.leading, 64)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                                )
                                .padding(.top, 4)
                            }
                            
                            // Loading indicator
                            if viewModel.isSearching {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Buscando usuarios...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monto a transferir")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(selectedCurrency.symbol)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.primary)

                                TextField("0.00", text: $viewModel.transferAmount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.leading)
                                    .focused($focusedField, equals: .amount)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )

                            Text("Saldo disponible: \(selectedCurrency.symbol)\(String(format: "%.2f", viewModel.balance(for: selectedCurrency))) \(selectedCurrency.currencyCode)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedCurrency.activeColor)
                        }

                        HStack(spacing: 12) {
                            ForEach(quickAmounts, id: \.self) { amount in
                                Button(action: {
                                    viewModel.transferAmount = String(format: "%.0f", amount)
                                    viewModel.sanitizeTransferAmount()
                                    focusedField = .amount
                                }) {
                                    Text("\(selectedCurrency.symbol)\(Int(amount))")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedCurrency.activeColor)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(selectedCurrency.activeColor.opacity(0.12))
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button(action: {
                        viewModel.performTransfer(for: selectedCurrency)
                    }) {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Transferir ahora")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            selectedCurrency.activeColor,
                                            selectedCurrency.activeColor.opacity(0.85)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .disabled(!viewModel.isTransferFormValid || viewModel.isLoading)
                    .opacity(viewModel.isTransferFormValid ? 1 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)

                    Spacer(minLength: 32)
                }
                .padding(.vertical)
            }
            .navigationTitle("Transferir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        viewModel.showTransferSheet = false
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .username
            }
            .onChange(of: viewModel.transferAmount) { _, _ in
                viewModel.sanitizeTransferAmount()
            }
        }
    }
}

// MARK: - Refund Info Sheet
struct RefundInfoSheet: View {
    let currency: WalletCurrency
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(currency.activeColor)

                Text("Solicitar reembolso")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)

                Text("Podrás solicitar un reembolso de tu saldo en \(currency.currencyCode). Nuestro equipo te guiará para completar el proceso en pocos minutos.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    dismiss()
                }) {
                    Text("Entendido")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(currency.activeColor)
                        )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Reembolsar")
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

// MARK: - Stripe Payment Sheet Presenter
struct StripePaymentSheetPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let paymentSheet: PaymentSheet?
    let onCompletion: (PaymentSheetResult) -> Void
    
    func makeUIViewController(context: Context) -> StripePaymentSheetViewController {
        StripePaymentSheetViewController()
    }
    
    func updateUIViewController(_ uiViewController: StripePaymentSheetViewController, context: Context) {
        if isPresented, let paymentSheet = paymentSheet, !uiViewController.isPresenting {
            uiViewController.isPresenting = true
            
            // Esperar un momento para que el sheet de recarga se cierre
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                paymentSheet.present(from: uiViewController) { result in
                    onCompletion(result)
                    isPresented = false
                    uiViewController.isPresenting = false
                }
            }
        }
    }
}

class StripePaymentSheetViewController: UIViewController {
    var isPresenting = false
}

#Preview {
    NavigationView {
        WalletView()
    }
}
