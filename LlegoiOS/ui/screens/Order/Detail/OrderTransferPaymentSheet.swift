import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

struct OrderTransferPaymentSheet: View {
    let order: OrderDetail
    let paymentAttemptId: String
    let isConfirming: Bool
    let onConfirm: (Data?) -> Void
    let onDismiss: () -> Void

    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedImage: PhotosPickerItem?
    @State private var proofImage: UIImage?
    @State private var showCopiedFeedback = false
    @State private var copiedText = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.feedBackground(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 24)

                        if order.transferAccounts.isEmpty {
                            noAccountsPlaceholder
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        } else {
                            accountsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        }

                        if !order.transferPhones.isEmpty {
                            phonesSection
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }

                        proofSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        confirmButton
                            .padding(.horizontal, 20)
                            .padding(.top, 28)
                            .padding(.bottom, 40)
                    }
                }

                if showCopiedFeedback {
                    copiedToast
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationTitle("Pagar por transferencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .onChange(of: selectedImage) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                {
                    proofImage = image
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Store avatar
            CachedAsyncImage(
                url: ImageURLResolver.resolve(order.branchImageUrl),
                cacheKey: order.branchId + "_transfer"
            ) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    gradientManager.currentAccentColor.opacity(0.12)
                    Image(systemName: "storefront")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            } failure: {
                ZStack {
                    gradientManager.currentAccentColor.opacity(0.12)
                    Image(systemName: "storefront")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(gradientManager.currentAccentColor)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(gradientManager.currentAccentColor.opacity(0.2), lineWidth: 2)
            )

            VStack(spacing: 6) {
                Text(order.branchName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                Text("Pedido \(order.orderNumber.suffix(6))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("Total a pagar:")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                    Text(order.formattedTotal)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(gradientManager.currentAccentColor)
                    Text(order.currency.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Accounts Section

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tarjetas del negocio", systemImage: "creditcard.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            Text("Realiza la transferencia a una de estas tarjetas por el monto exacto indicado arriba.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(order.transferAccounts) { account in
                    TransferAccountCard(account: account) { number in
                        copyToClipboard(number, label: "Número copiado")
                    }
                }
            }
        }
    }

    private var noAccountsPlaceholder: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            Text("Este negocio aún no tiene tarjetas de transferencia configuradas. Contáctalos directamente.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
    }

    // MARK: - Phones Section

    private var phonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Número para SMS de verificación", systemImage: "message.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            // Explicación del flujo cubano de Transfermóvil
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 1)
                Text("Al hacer la transferencia en Transfermóvil, escribe este número en el campo opcional de teléfono. El banco enviará un SMS al negocio para confirmar tu pago.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 8) {
                ForEach(order.transferPhones) { entry in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(gradientManager.currentAccentColor.opacity(0.1))
                                .frame(width: 40, height: 40)
                            Image(systemName: "message.fill")
                                .font(.system(size: 15))
                                .foregroundColor(gradientManager.currentAccentColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Número de confirmación")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            Text(entry.phone)
                                .font(.system(size: 17, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                                .tracking(1)
                        }

                        Spacer()

                        Button {
                            copyToClipboard(entry.phone, label: "Número copiado")
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Copiar")
                                    .font(.system(size: 13, weight: .semibold))
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
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.cardBackground(colorScheme))
                            .shadow(
                                color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06),
                                radius: 6, x: 0, y: 3)
                    )
                }
            }
        }
    }

    // MARK: - Proof Section

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Comprobante de pago", systemImage: "doc.viewfinder")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            // Info banner
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15))
                    .foregroundColor(gradientManager.currentAccentColor)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 3) {
                    Text("No es obligatorio, pero ayuda mucho")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                    Text("Algunos negocios no confirman el pedido hasta ver el comprobante. Sube la captura del mensaje de tu banco para que todo vaya más rápido.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradientManager.currentAccentColor.opacity(0.08))
            )

            // Image picker
            PhotosPicker(selection: $selectedImage, matching: .images) {
                if let proofImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: proofImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Label("Cambiar", systemImage: "pencil.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.black.opacity(0.5))
                            )
                            .padding(10)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(gradientManager.currentAccentColor)

                        VStack(spacing: 3) {
                            Text("Subir captura del banco")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                            Text("Toca para elegir una imagen de tu galería")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 130)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(gradientManager.currentAccentColor.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                    )
                                    .foregroundColor(gradientManager.currentAccentColor.opacity(0.3))
                            )
                    )
                }
            }
        }
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        VStack(spacing: 12) {
            Button {
                let imageData = proofImage.flatMap {
                    $0.scaled(toMaxDimension: 1000)?.jpegData(compressionQuality: 0.5)
                }
                onConfirm(imageData)
            } label: {
                HStack(spacing: 10) {
                    if isConfirming {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                    }
                    Text(isConfirming ? "Enviando confirmación..." : "Ya realicé la transferencia")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(gradientManager.currentAccentColor)
            .disabled(isConfirming)

            Text("El negocio revisará tu pago y confirmará el pedido.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Text(copiedText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
    }

    // MARK: - Actions

    private func copyToClipboard(_ text: String, label: String) {
        UIPasteboard.general.string = text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        copiedText = label
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showCopiedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showCopiedFeedback = false
            }
        }
    }

}

// MARK: - Transfer Account Card

private struct TransferAccountCard: View {
    let account: OrderTransferAccount
    let onCopy: (String) -> Void

    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Bank name row
            HStack {
                Image(systemName: "phone.fill")
                    .font(.system(size: 13))
                    .foregroundColor(gradientManager.currentAccentColor)
                Text(account.confirmPhone)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("CUP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(gradientManager.currentAccentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(gradientManager.currentAccentColor.opacity(0.1))
                    )
            }

            Divider()
                .padding(.vertical, 10)

            // Card number row
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Número de tarjeta")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedCardNumber)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                        .tracking(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Button {
                    onCopy(account.cardNumber.replacingOccurrences(of: " ", with: ""))
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Copiar número")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(gradientManager.currentAccentColor)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.vertical, 10)

            // Card holder
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("A nombre de")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(account.cardHolderName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                Spacer()
            }

            // Pago QR
            if let qrString = account.pagoQr, !qrString.isEmpty,
                let qrImage = generateQRCode(from: qrString)
            {
                Divider()
                    .padding(.vertical, 10)

                VStack(spacing: 10) {
                    Label("Pago QR", systemImage: "qrcode")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Escanea con tu app de banco para pagar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground(colorScheme))
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.25 : 0.07),
                    radius: 8, x: 0, y: 4)
        )
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scale = UIScreen.main.scale * 8
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    private var formattedCardNumber: String {
        let digits = account.cardNumber.replacingOccurrences(of: " ", with: "")
        guard digits.count == 16 else { return account.cardNumber }
        return stride(from: 0, to: digits.count, by: 4)
            .map { i -> String in
                let start = digits.index(digits.startIndex, offsetBy: i)
                let end = digits.index(start, offsetBy: min(4, digits.count - i))
                return String(digits[start..<end])
            }
            .joined(separator: "  ")
    }
}

// MARK: - UIImage scaling helper

private extension UIImage {
    func scaled(toMaxDimension maxDimension: CGFloat) -> UIImage? {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
