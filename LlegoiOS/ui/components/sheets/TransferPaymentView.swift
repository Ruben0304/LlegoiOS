import CoreLocation
import PhotosUI
import SwiftUI

// MARK: - Payment Card Model
struct BusinessPaymentCard: Identifiable {
    let id: String
    let name: String
    let cardNumber: String
    let fullCardNumber: String
    let cardHolder: String
    let bankName: String
    let type: PaymentCardType
    let icon: String

    enum PaymentCardType {
        case online
        case alternative
    }
}

struct TransferPaymentView: View {
    let order: RecentOrder
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    // Estados para la selección de tarjeta
    @State private var selectedCard: BusinessPaymentCard?
    @State private var showCardSelection = true
    @State private var showCopiedFeedback = false

    // Estados para el pago
    @State private var selectedImage: PhotosPickerItem?
    @State private var transferImage: UIImage?
    @State private var transferReference = ""
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    private let cartRepository = CartRepository()

    // Tarjetas del negocio
    private let businessCards: [BusinessPaymentCard] = [
        BusinessPaymentCard(
            id: "1",
            name: "Pago en Línea",
            cardNumber: "•••• 5678",
            fullCardNumber: "9225 8801 2345 5678",
            cardHolder: "Comercio Llegó",
            bankName: "Banco Popular de Ahorro",
            type: .online,
            icon: "qrcode"
        ),
        BusinessPaymentCard(
            id: "2",
            name: "Transferencia Directa",
            cardNumber: "•••• 1234",
            fullCardNumber: "9225 8801 6789 1234",
            cardHolder: "Comercio Llegó",
            bankName: "Banco Metropolitano",
            type: .alternative,
            icon: "creditcard"
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.feedBackground(colorScheme)
                    .ignoresSafeArea()

                if showCardSelection {
                    cardSelectionView
                } else {
                    paymentDetailsView
                }
            }
            .navigationTitle(showCardSelection ? "Seleccionar Tarjeta" : "Pagar por Transferencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if showCardSelection {
                            dismiss()
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showCardSelection = true
                                selectedCard = nil
                            }
                        }
                    } label: {
                        Image(
                            systemName: showCardSelection
                                ? "xmark.circle.fill" : "chevron.left.circle.fill"
                        )
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                        .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("¡Pago Enviado!", isPresented: $showSuccess) {
                Button("Entendido") {
                    dismiss()
                }
            } message: {
                Text(
                    "Tu comprobante fue enviado para validación. El estado del pedido seguirá el flujo real del backend."
                )
            }
            .overlay(alignment: .top) {
                if showCopiedFeedback {
                    copiedFeedbackView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onChange(of: selectedImage) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                {
                    transferImage = image
                }
            }
        }
    }

    // MARK: - Card Selection View

    private var cardSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                orderInfoSection

                Text("Selecciona una tarjeta")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                VStack(spacing: 12) {
                    ForEach(businessCards) { card in
                        BusinessCardView(card: card) {
                            selectCard(card)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Payment Details View

    private var paymentDetailsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let selectedCard = selectedCard {
                    selectedCardInfoSection(card: selectedCard)

                    if selectedCard.type == .online {
                        qrCodeSection
                    } else {
                        manualTransferSection
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Order Info Section

    private var orderInfoSection: some View {
        VStack(spacing: 16) {
            // Logo de la tienda
            AsyncImage(url: URL(string: order.storeImageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    gradientManager.currentAccentColor.opacity(0.2), lineWidth: 2)
                        )
                case .failure, .empty:
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentAccentColor.opacity(0.12))
                            .frame(width: 72, height: 72)

                        Image(systemName: "storefront")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                @unknown default:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 72, height: 72)

                        ProgressView()
                            .tint(gradientManager.currentAccentColor)
                    }
                }
            }

            VStack(spacing: 8) {
                Text(order.storeName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                Text("Pedido #\(order.orderNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                // Monto a pagar
                HStack(spacing: 6) {
                    Text("Total:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(String(format: "$%.2f", order.total))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(gradientManager.currentAccentColor)

                    Text("CUP")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    // MARK: - Selected Card Info Section

    private func selectedCardInfoSection(card: BusinessPaymentCard) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradientManager.currentAccentColor.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: card.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Text(card.bankName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if card.type == .alternative {
                Divider()

                // Titular
                HStack {
                    Text("Titular")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(card.cardHolder)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                }

                // Número de tarjeta con botón copiar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Número de Tarjeta")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Text(card.fullCardNumber)
                            .font(.system(size: 17, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                        Spacer()

                        Button {
                            copyToClipboard(card.fullCardNumber)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Copiar")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(gradientManager.currentAccentColor)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(gradientManager.currentAccentColor.opacity(0.08))
                    )
                }
            }

            if card.type == .alternative {
                Text("A través de esta vía también puedes pagar con iPhone")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 8, x: 0,
                    y: 4)
        )
    }

    // MARK: - QR Code Section

    private var qrCodeSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "qrcode")
                    .font(.system(size: 16))
                    .foregroundColor(gradientManager.currentAccentColor)

                Text("Escanea el código QR")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
            }

            // QR Code
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 170))
                        .foregroundColor(.black)

                    Text("QR de Prueba")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            // Instrucciones del QR
            VStack(alignment: .leading, spacing: 10) {
                instructionRow(number: "1", text: "Abre tu app de banca móvil")
                instructionRow(number: "2", text: "Selecciona 'Pagar con QR'")
                instructionRow(number: "3", text: "Escanea este código")

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentAccentColor)
                            .frame(width: 24, height: 24)

                        Text("4")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Confirma el pago por \(String(format: "$%.2f", order.total)) CUP")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradientManager.currentAccentColor.opacity(0.08))
            )

            // Botón confirmación QR
            Button {
                confirmQRPayment()
            } label: {
                HStack(spacing: 12) {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Ya realicé el pago")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientManager.currentAccentColor,
                                    gradientManager.currentAccentColor.opacity(0.8),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .disabled(isProcessing)
            .padding(.top, 8)
        }
    }

    // MARK: - Manual Transfer Section

    private var manualTransferSection: some View {
        VStack(spacing: 24) {
            instructionsSection
            uploadSection
            referenceSection
            confirmButton
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(gradientManager.currentAccentColor)

                Text("Instrucciones")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
            }

            VStack(alignment: .leading, spacing: 8) {
                instructionRow(
                    number: "1",
                    text: "Realiza la transferencia bancaria por el monto indicado")
                instructionRow(number: "2", text: "Toma una captura del comprobante de pago")
                instructionRow(number: "3", text: "Sube la imagen y agrega la referencia")
                instructionRow(number: "4", text: "Confirma el pago y espera la validación")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(gradientManager.currentAccentColor.opacity(0.08))
        )
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(gradientManager.currentAccentColor)
                    .frame(width: 24, height: 24)

                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Upload Section

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comprobante de Pago")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            PhotosPicker(selection: $selectedImage, matching: .images) {
                if let transferImage = transferImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: transferImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Button {
                            // PhotosPicker se abre automáticamente
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(gradientManager.currentAccentColor)
                                        .frame(width: 34, height: 34)
                                )
                        }
                        .padding(12)
                    }
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44))
                            .foregroundColor(gradientManager.currentAccentColor)

                        VStack(spacing: 3) {
                            Text("Subir Comprobante")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                            Text("Toca para seleccionar una imagen")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(gradientManager.currentAccentColor.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1.5, dash: [8])
                                    )
                                    .foregroundColor(
                                        gradientManager.currentAccentColor.opacity(0.3))
                            )
                    )
                }
            }
        }
    }

    // MARK: - Reference Section

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Referencia de Transferencia")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            TextField("Ej: 123456789", text: $transferReference)
                .font(.system(size: 15, weight: .medium))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground(colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(gradientManager.currentAccentColor.opacity(0.2), lineWidth: 1)
                )
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            confirmPayment()
        } label: {
            HStack(spacing: 12) {
                if isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Confirmar Pago")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isFormValid
                            ? LinearGradient(
                                colors: [
                                    gradientManager.currentAccentColor,
                                    gradientManager.currentAccentColor.opacity(0.8),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
            )
        }
        .disabled(!isFormValid || isProcessing)
        .padding(.top, 8)
    }

    // MARK: - Helper Properties

    private var isFormValid: Bool {
        transferImage != nil && !transferReference.trimmedOrEmpty
    }

    private var copiedFeedbackView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text("Número copiado al portapapeles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.top, 60)
    }

    // MARK: - Actions

    private func selectCard(_ card: BusinessPaymentCard) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selectedCard = card
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCardSelection = false
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedFeedback = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showCopiedFeedback = false
            }
        }
    }

    private func confirmQRPayment() {
        isProcessing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isProcessing = false
            showSuccess = true
        }
    }

    private func confirmPayment() {
        guard isFormValid, let transferImage else { return }

        isProcessing = true

        cartRepository.validatePaymentImage(
            image: transferImage,
            transferId: transferReference
        ) { result in
            Task { @MainActor in
                isProcessing = false

                switch result {
                case .success(let validation):
                    if validation.matched {
                        showSuccess = true
                    } else {
                        errorMessage = validation.message
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Business Card View (Flat Design)

struct BusinessCardView: View {
    let card: BusinessPaymentCard
    let onSelect: () -> Void
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 14) {
                // Icono plano
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientManager.currentAccentColor.opacity(0.8),
                                    gradientManager.currentAccentColor.opacity(0.6),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: card.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Info
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Text(card.bankName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    if card.type == .alternative {
                        HStack(spacing: 6) {
                            Text(card.cardNumber)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("· CUP")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Etiquetas por tipo
                    if card.type == .alternative {
                        Text("Compatible con iPhone")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    } else if card.type == .online {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 10))
                            Text("Rápido")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .padding(.top, 2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(gradientManager.currentAccentColor.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - String Extension

extension String {
    fileprivate var trimmedOrEmpty: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

#Preview {
    TransferPaymentView(
        order: RecentOrder(
            id: "1",
            orderNumber: "ORD-12345",
            storeName: "Tienda Demo",
            storeImageUrl: nil,
            date: Date(),
            total: 1500.00,
            currency: "CUP",
            status: .pendingAcceptance,
            paymentStatus: .pending,
            itemCount: 3,
            items: [],
            fulfillmentMode: nil
        )
    )
}
