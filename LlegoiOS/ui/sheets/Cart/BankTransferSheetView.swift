import SwiftUI
import UIKit

struct BankTransferSheetView: View {
    let totalAmount: String
    let allowAmountEditing: Bool
    let onConfirm: (String) -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var gradientManager = GradientStateManager.shared
    @State private var editableAmount: String
    @State private var transferId: String = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var validationState: ValidationState = .idle
    @State private var isValidating = false
    @State private var validationError: String = ""
    @State private var showValidationError = false
    @State private var lastValidationResult: PaymentValidationResult?

    private let cartRepository = CartRepository()

    enum ValidationState: Equatable {
        case idle
        case validating
        case validated
        case failed(String)
    }

    init(
        totalAmount: String,
        allowAmountEditing: Bool = false,
        onConfirm: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.totalAmount = totalAmount
        self.allowAmountEditing = allowAmountEditing
        self.onConfirm = onConfirm
        self.onDismiss = onDismiss
        _editableAmount = State(initialValue: totalAmount)
    }

    let bankAccountNumber = "9225 8899 0012 3456"
    let phoneNumber = "+53 5234 5678"
    let bankName = "Banco Metropolitano"

    private var currentAmountText: String {
        let value = allowAmountEditing ? editableAmount : totalAmount
        return value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isAmountProvided: Bool {
        !currentAmountText.isEmpty
    }

    @ViewBuilder
    private func validationOverlay() -> some View {
        switch validationState {
        case .validating:
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    VStack(spacing: 16) {
                        LottieView(name: "loading")
                            .frame(width: 80, height: 80)
                        Text("Verificando comprobante...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                )
        case .validated:
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(gradientManager.currentAccentColor)
                            .frame(width: 40, height: 40)
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(
                        color: gradientManager.currentAccentColor.opacity(0.5), radius: 8, x: 0,
                        y: 4
                    )
                    .padding()
                }
                Spacer()
            }
        case .failed:
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 40, height: 40)
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.red.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding()
                }
                Spacer()
            }
        default:
            EmptyView()
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.llegoBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        titleSection

                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Banco")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(bankName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()
                            }

                            Divider()

                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Número de Tarjeta")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(bankAccountNumber)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()

                                Button(action: {
                                    UIPasteboard.general.string = bankAccountNumber
                                }) {
                                    Image(systemName: "doc.on.doc.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                        .padding(8)
                                        .background(
                                            Circle().fill(
                                                gradientManager.currentAccentColor.opacity(0.15)))
                                }
                            }

                            Divider()

                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.llegoSecondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Teléfono de Confirmación")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    Text(phoneNumber)
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(gradientManager.currentAccentColor)
                                }

                                Spacer()
                            }

                            Divider()

                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monto a Transferir")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    if allowAmountEditing {
                                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                                            TextField("0.00", text: $editableAmount)
                                                .font(
                                                    .system(
                                                        size: 20, weight: .bold, design: .rounded)
                                                )
                                                .keyboardType(.decimalPad)
                                                .foregroundColor(gradientManager.currentAccentColor)
                                                .multilineTextAlignment(.leading)

                                            Text("CUP")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(
                                                    gradientManager.currentAccentColor.opacity(0.85)
                                                )
                                        }
                                    } else {
                                        Text(totalAmount)
                                            .font(
                                                .system(size: 20, weight: .bold, design: .rounded)
                                            )
                                            .foregroundColor(gradientManager.currentAccentColor)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                        )
                        .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "number.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Identificador de Transferencia")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Spacer()
                            }

                            TextField("Ej: 1234567890", text: $transferId)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(
                                                    transferId.isEmpty
                                                        ? Color.gray.opacity(0.3)
                                                        : gradientManager.currentAccentColor,
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                                .autocapitalization(.none)
                                .keyboardType(.numberPad)
                        }
                        .padding(.horizontal, 20)

                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "photo.badge.plus.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Text("Comprobante de Pago")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(gradientManager.currentAccentColor)

                                Spacer()

                                if validationState == .validated {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Verificado")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(gradientManager.currentAccentColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(gradientManager.currentAccentColor.opacity(0.15))
                                    )
                                }
                            }

                            if let image = selectedImage {
                                ZStack {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))

                                    validationOverlay()
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            strokeColorForValidationState(),
                                            lineWidth: 2
                                        )
                                )

                                if case .validating = validationState {
                                    EmptyView()
                                } else {
                                    Button(action: {
                                        validationState = .idle
                                        lastValidationResult = nil
                                        showImagePicker = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Cambiar imagen")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(gradientManager.currentAccentColor)
                                        .padding(.vertical, 8)
                                    }
                                }

                                if let validationResult = lastValidationResult {
                                    validationResultSummary(result: validationResult)
                                        .padding(.top, 12)
                                }
                            } else {
                                Button(action: {
                                    if !transferId.isEmpty {
                                        showImagePicker = true
                                    }
                                }) {
                                    VStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.llegoSecondary.opacity(0.15))
                                                .frame(width: 60, height: 60)

                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 28, weight: .medium))
                                                .foregroundColor(.llegoSecondary)
                                        }

                                        Text("Subir Comprobante")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(
                                                transferId.isEmpty
                                                    ? .gray : gradientManager.currentAccentColor)

                                        Text(
                                            transferId.isEmpty
                                                ? "Primero introduce el identificador"
                                                : "Toca para seleccionar una imagen"
                                        )
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 180)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                            )
                                            .foregroundColor(Color.llegoSecondary.opacity(0.3))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Button(action: {
                            onConfirm(currentAmountText)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))

                                Text("Confirmar Transferencia")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        gradientManager.currentAccentColor,
                                        gradientManager.currentAccentColor,
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: validationState == .validated
                                    ? gradientManager.currentAccentColor.opacity(0.4)
                                    : Color.gray.opacity(0.2),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(validationState != .validated || !isAmountProvided)
                        .opacity(validationState == .validated && isAmountProvided ? 1.0 : 0.4)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Transferencia Bancaria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    image: $selectedImage,
                    onImageSelected: {
                        validateReceipt()
                    })
            }
            .alert("Error de Validación", isPresented: $showValidationError) {
                Button("OK", role: .cancel) {
                    showValidationError = false
                }
            } message: {
                Text(validationError)
            }
        }
    }

    private var headerSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.llegoSecondary.opacity(0.2),
                            Color.llegoSecondary.opacity(0.1),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: "building.columns.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(Color.llegoSecondary)
        }
        .padding(.top, 20)
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Transferencia Bancaria")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(gradientManager.currentAccentColor)

            Text("Realiza tu transferencia y sube el comprobante")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
    }

    private func strokeColorForValidationState() -> Color {
        switch validationState {
        case .validated:
            return gradientManager.currentAccentColor
        case .failed:
            return Color.red
        default:
            return Color.gray.opacity(0.3)
        }
    }

    private func validationResultSummary(result: PaymentValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(
                    systemName: result.matched
                        ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
                )
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(result.matched ? gradientManager.currentAccentColor : .red)

                Text(result.matched ? "Transferencia validada" : "Verifica el identificador")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(result.matched ? gradientManager.currentAccentColor : .red)

                Spacer()
            }

            if let detected = result.detectedTransferId, !detected.isEmpty {
                validationDetailRow(title: "ID detectado", value: detected)
            }

            if let data = result.extractedData {
                if let banco = data.banco, !banco.isEmpty {
                    validationDetailRow(title: "Banco", value: banco)
                }
                if let quienEnvio = data.quienEnvio, !quienEnvio.isEmpty {
                    validationDetailRow(title: "Quién envió", value: quienEnvio)
                }
                if let fecha = data.fecha, !fecha.isEmpty {
                    validationDetailRow(title: "Fecha", value: fecha)
                }
                if let monto = data.cantidadTransferida {
                    validationDetailRow(
                        title: "Monto detectado", value: String(format: "%.2f CUP", monto))
                }
                if let numero = data.numeroTransferencia, !numero.isEmpty {
                    validationDetailRow(title: "Número en comprobante", value: numero)
                }
            }

            if let savedId = result.savedPayment?.id, !savedId.isEmpty {
                validationDetailRow(title: "Registro guardado", value: savedId)
            }

            Text(result.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    result.matched
                        ? gradientManager.currentAccentColor.opacity(0.4) : Color.red.opacity(0.4),
                    lineWidth: 1.5
                )
        )
    }

    private func validationDetailRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(gradientManager.currentAccentColor)
        }
    }

    private func validateReceipt() {
        guard let image = selectedImage else { return }
        guard !transferId.isEmpty else {
            validationError = "Debes introducir el identificador de transferencia primero"
            showValidationError = true
            return
        }

        validationState = .validating
        lastValidationResult = nil
        let enteredTransferId = transferId

        cartRepository.validatePaymentImage(image: image, transferId: transferId) { result in
            Task { @MainActor in
                switch result {
                case .success(let paymentResult):
                    lastValidationResult = paymentResult

                    if let isBankMessage = paymentResult.extractedData?.esMensajeBanco,
                        isBankMessage == false
                    {
                        let errorMsg = "La imagen no parece ser un mensaje de banco válido."
                        validationState = .failed(errorMsg)
                        validationError = errorMsg
                        showValidationError = true
                        print("❌ Validación fallida: \(errorMsg)")
                        return
                    }

                    guard paymentResult.matched else {
                        let detected =
                            paymentResult.detectedTransferId ?? paymentResult.extractedData?
                            .numeroTransferencia ?? "no detectado"
                        let errorMsg = """
                            El identificador no coincide.
                            Ingresado: \(enteredTransferId)
                            Detectado: \(detected)
                            \(paymentResult.message)
                            """
                        validationState = .failed(errorMsg)
                        validationError = errorMsg
                        showValidationError = true
                        print("❌ Validación fallida: \(errorMsg)")
                        return
                    }

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        validationState = .validated
                    }
                    showValidationError = false
                    validationError = ""

                    print("✅ Validación exitosa!")
                    print("   Message: \(paymentResult.message)")
                    print("   Detectado: \(paymentResult.detectedTransferId ?? "n/a")")
                    if let banco = paymentResult.extractedData?.banco {
                        print("   Banco: \(banco)")
                    }
                    if let monto = paymentResult.extractedData?.cantidadTransferida {
                        print("   Monto: \(monto)")
                    }

                case .failure(let error):
                    lastValidationResult = nil
                    let errorMsg = "Error al validar: \(error.localizedDescription)"
                    validationState = .failed(errorMsg)
                    validationError = errorMsg
                    showValidationError = true
                    print("❌ Error de validación: \(errorMsg)")
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: () -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected()
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
