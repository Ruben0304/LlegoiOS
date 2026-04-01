import AVFoundation
import Combine
import CryptoKit
import SwiftUI
import UIKit

private enum CartAccountCashKycUIState: Equatable {
    case idle
    case loadingStatus
    case readyToStart
    case submitting
    case waitingResult
    case approved
    case rejected
    case insufficientData
    case error
    case expired
    case cashAvailableUncovered
    case cashAvailableCovered
    case cashBlocked
}

@MainActor
private final class CartAccountCashKycViewModel: ObservableObject {
    @Published var state: CartAccountCashKycUIState = .idle
    @Published var title: String = "Verificacion de cuenta"
    @Published var message: String = "Consulta tu estado global para pagos en efectivo."
    @Published var documentImage: UIImage?
    @Published var selfieImage: UIImage?

    private let paymentRepository = PaymentRepository()

    var canSubmitEvidence: Bool { documentImage != nil && selfieImage != nil }

    func load() {
        Task {
            guard let jwt = await MainActor.run(body: { AuthManager.shared.getAccessToken() }) else {
                applyError("No hay sesion activa.")
                return
            }

            state = .loadingStatus
            title = "Consultando estado"
            message = "Estamos consultando si tu KYC ya esta habilitado para efectivo."

            do {
                let status = try await paymentRepository.globalCashKycStatus(jwt: jwt)
                if applyDecision(status) == .waitingResult {
                    await pollStatus(jwt: jwt)
                }
            } catch {
                applyError(userFriendlyError(error.localizedDescription))
            }
        }
    }

    func submitAccountVerification() {
        guard let documentData = documentImage?.jpegData(compressionQuality: 0.8),
            let selfieData = selfieImage?.jpegData(compressionQuality: 0.8)
        else {
            state = .readyToStart
            title = "Evidencia incompleta"
            message = "Debes capturar documento y selfie."
            return
        }

        Task {
            guard let jwt = await MainActor.run(body: { AuthManager.shared.getAccessToken() }) else {
                applyError("No hay sesion activa.")
                return
            }

            state = .submitting
            title = "Enviando evidencia"
            message = "Estamos enviando tus fotos para validar tu identidad."

            do {
                let decision = try await paymentRepository.startGlobalCashKycEvaluation(
                    identityDocumentFrontBase64: documentData.base64EncodedString(),
                    selfieWithIdBase64: selfieData.base64EncodedString(),
                    deviceContext: buildDeviceContext(),
                    jwt: jwt
                )
                if applyDecision(decision) == .waitingResult {
                    await pollStatus(jwt: jwt)
                }
            } catch {
                applyError(userFriendlyError(error.localizedDescription))
            }
        }
    }

    func clearEvidence() {
        documentImage = nil
        selfieImage = nil
    }

    @discardableResult
    private func applyDecision(_ decision: CashKycDecisionSnapshot) -> CartAccountCashKycUIState {
        if decision.allowCash {
            if decision.appCoversCash {
                state = .cashAvailableCovered
                title = "KYC aprobado"
                message = "Tu cuenta ya esta verificada y puede pagar en efectivo."
                return .cashAvailableCovered
            }

            state = .cashAvailableUncovered
            title = "KYC aprobado sin cobertura"
            message = "Tu cuenta puede pagar en efectivo, pero sin cobertura de la app."
            return .cashAvailableUncovered
        }

        switch decision.kycEvalStatus {
        case .pendingEvidence, .notRequired:
            state = .readyToStart
            title = "KYC pendiente"
            message = "Debes subir documento y selfie para habilitar pagos en efectivo."
            return .readyToStart
        case .submitted:
            state = .waitingResult
            title = "KYC en revision"
            message = "Ya recibimos tus fotos y estamos revisando la verificacion."
            return .waitingResult
        case .approved:
            state = .approved
            title = "KYC aprobado"
            message = "Tu cuenta quedo verificada para pagar en efectivo."
            return .approved
        case .rejected:
            state = .rejected
            title = "KYC rechazado"
            message = "No pudimos aprobar la verificacion con las fotos enviadas."
            return .rejected
        case .insufficientData:
            state = .insufficientData
            title = "KYC incompleto"
            message = preferredKycMessage(
                decision,
                fallback: "Necesitamos fotos mas claras del documento y la selfie."
            )
            return .insufficientData
        case .error:
            state = .error
            title = "KYC no disponible"
            message = preferredKycMessage(
                decision,
                fallback: "No pudimos validar tu identidad ahora mismo. Intenta nuevamente en unos minutos."
            )
            return .error
        case .expired:
            state = .expired
            title = "KYC vencido"
            message = "Tu verificacion vencio y debes enviar las fotos otra vez."
            return .expired
        case .needsReview:
            state = .cashBlocked
            title = "KYC en revision manual"
            message = "Por ahora no puedes usar efectivo hasta que termine la revision."
            return .cashBlocked
        case .unknown:
            state = .error
            title = "KYC sin estado claro"
            message = "No pudimos determinar el estado de tu verificacion."
            return .error
        }
    }

    private func pollStatus(jwt: String) async {
        for _ in 0..<8 {
            do {
                let status = try await paymentRepository.globalCashKycStatus(jwt: jwt)
                if applyDecision(status) != .waitingResult {
                    return
                }
            } catch {
                applyError("No se pudo actualizar el estado. Intenta de nuevo.")
                return
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }

        state = .error
        title = "Tiempo de espera agotado"
        message = "No se recibio un resultado final. Actualiza nuevamente."
    }

    private func applyError(_ message: String) {
        state = .error
        title = "Error de verificacion"
        self.message = message
    }

    private func preferredKycMessage(_ decision: CashKycDecisionSnapshot, fallback: String) -> String {
        if decision.providerErrorCode == "GEMINI_MODEL_OVERLOADED" {
            return "El servicio de verificacion esta saturado temporalmente. Intenta de nuevo en unos minutos."
        }

        let trimmedProviderError = decision.providerError?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedProviderError, !trimmedProviderError.isEmpty {
            return trimmedProviderError
        }

        let trimmedBackendMessage = decision.backendMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmedBackendMessage, !trimmedBackendMessage.isEmpty {
            return trimmedBackendMessage
        }

        return fallback
    }

    private func userFriendlyError(_ raw: String) -> String {
        if raw.contains("RETRY_NOT_SUPPORTED_FOR_ACCOUNT_VERIFICATION") {
            return "Este flujo no permite reintento directo. Envia una nueva evidencia desde esta pantalla."
        }
        return raw
    }

    private func buildDeviceContext() -> [String: Any] {
        let rawDeviceId = DeviceIDManager.shared.getDeviceId() ?? UUID().uuidString
        let deviceIdHash = SHA256.hash(data: Data(rawDeviceId.utf8)).compactMap {
            String(format: "%02x", $0)
        }.joined()
        let ipHash = SHA256.hash(data: Data("ip_unavailable".utf8)).compactMap {
            String(format: "%02x", $0)
        }.joined()
        let appVersion =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        return [
            "deviceIdHash": deviceIdHash,
            "ipHash": ipHash,
            "appVersion": "\(appVersion) (\(buildNumber))",
            "os": "iOS \(UIDevice.current.systemVersion)",
        ]
    }
}

struct CartAccountCashKycSheet: View {
    let onCompleted: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = CartAccountCashKycViewModel()
    @StateObject private var gradientManager = GradientStateManager.shared
    @State private var showDocumentCamera = false
    @State private var showSelfieCamera = false
    @State private var showDocumentLibrary = false
    @State private var showSelfieLibrary = false
    @State private var showDocumentSourceDialog = false
    @State private var showSelfieSourceDialog = false
    @State private var showPermissionAlert = false
    @State private var permissionMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.feedBackground(colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        introSection
                        purposeSection

                        if shouldShowCapture {
                            captureCard(
                                title: "Documento de identidad",
                                subtitle: "Frente del carnet o documento oficial",
                                icon: "creditcard.viewfinder",
                                image: viewModel.documentImage
                            ) {
                                showDocumentSourceDialog = true
                            }

                            captureCard(
                                title: "Selfie con documento",
                                subtitle: "Sosten el carnet visible en la foto",
                                icon: "person.crop.square.filled.and.at.rectangle",
                                image: viewModel.selfieImage
                            ) {
                                showSelfieSourceDialog = true
                            }
                        }

                        actionsPanel
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Verificacion KYC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.clearEvidence()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .sheet(isPresented: $showDocumentCamera) {
                CartKycImagePicker(image: $viewModel.documentImage, sourceType: .camera)
            }
            .sheet(isPresented: $showSelfieCamera) {
                CartKycImagePicker(image: $viewModel.selfieImage, sourceType: .camera)
            }
            .sheet(isPresented: $showDocumentLibrary) {
                CartKycImagePicker(image: $viewModel.documentImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showSelfieLibrary) {
                CartKycImagePicker(image: $viewModel.selfieImage, sourceType: .photoLibrary)
            }
            .confirmationDialog(
                "Documento de identidad",
                isPresented: $showDocumentSourceDialog,
                titleVisibility: .visible
            ) {
                Button("Tomar foto") { openCamera(target: .document) }
                Button("Elegir de galeria") { showDocumentLibrary = true }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Selecciona como agregar la foto del documento")
            }
            .confirmationDialog(
                "Selfie con documento",
                isPresented: $showSelfieSourceDialog,
                titleVisibility: .visible
            ) {
                Button("Tomar foto") { openCamera(target: .selfie) }
                Button("Elegir de galeria") { showSelfieLibrary = true }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Selecciona como agregar la selfie")
            }
            .alert("Permiso de camara", isPresented: $showPermissionAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(permissionMessage)
            }
            .onAppear {
                viewModel.load()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(gradientManager.currentAccentColor.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: "checkmark.shield")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            Text("Verificacion KYC")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))

            Spacer(minLength: 0)
        }
        .padding(.top, 6)
    }

    private var introSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verifica tu identidad para poder pagar en efectivo cuando el negocio lo requiera.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var purposeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sirve para")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(gradientManager.currentAccentColor)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(gradientManager.currentAccentColor.opacity(0.10))
                        .frame(width: 40, height: 40)

                    Image(systemName: "banknote")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Pagar en efectivo")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Text("Solo tomara unos segundos activar esta verificacion.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(surfaceCard)
    }

    private func captureCard(
        title: String,
        subtitle: String,
        icon: String,
        image: UIImage?,
        action: @escaping () -> Void
    ) -> some View {
        let isComplete = image != nil

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isComplete ? Color.clear : gradientManager.currentAccentColor.opacity(0.08))
                        .frame(width: 84, height: 84)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    isComplete
                                        ? Color.green.opacity(0.26)
                                        : gradientManager.currentAccentColor.opacity(0.16),
                                    lineWidth: 1
                                )
                        )

                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white, .green)
                            .background(Color.white, in: Circle())
                            .offset(x: 6, y: -6)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(gradientManager.currentAccentColor)
                            .frame(width: 84, height: 84, alignment: .center)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Color.adaptiveOnSurface(colorScheme))

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isComplete ? Color.green : gradientManager.currentAccentColor)
                            .frame(width: 7, height: 7)
                        Text(isComplete ? "Foto agregada" : "Pendiente")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isComplete ? .green : gradientManager.currentAccentColor)
                    }
                }

                Spacer(minLength: 0)
            }

            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: isComplete ? "arrow.triangle.2.circlepath" : "plus")
                    Text(isComplete ? "Cambiar foto" : "Agregar foto")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isComplete ? Color.adaptiveOnSurface(colorScheme) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            isComplete
                                ? Color.primary.opacity(0.06)
                                : gradientManager.currentAccentColor
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(surfaceCard)
    }

    @ViewBuilder
    private var actionsPanel: some View {
        switch viewModel.state {
        case .approved, .cashAvailableCovered, .cashAvailableUncovered:
            Button(action: {
                onCompleted("Verificacion consultada correctamente.")
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Listo")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

        case .rejected, .cashBlocked:
            Button(action: {
                onCompleted("Actualmente no esta habilitado el pago en efectivo para tu cuenta.")
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("Entendido")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(gradientManager.currentAccentColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

        case .readyToStart, .insufficientData, .error, .expired:
            Button(action: {
                viewModel.submitAccountVerification()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                    Text("Enviar verificacion")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    viewModel.canSubmitEvidence
                        ? gradientManager.currentAccentColor : Color.gray.opacity(0.35)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canSubmitEvidence)

        case .waitingResult, .loadingStatus, .submitting:
            HStack(spacing: 12) {
                ProgressView()
                    .tint(gradientManager.currentAccentColor)
                Text("Procesando verificacion...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(gradientManager.currentAccentColor.opacity(0.08))
            )

        default:
            EmptyView()
        }
    }

    private var surfaceCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 18, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.55), lineWidth: 1)
            )
    }

    private var shouldShowCapture: Bool {
        [.readyToStart, .insufficientData, .error, .expired].contains(viewModel.state)
    }

    private enum CameraTarget {
        case document
        case selfie
    }

    private func openCamera(target: CameraTarget) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera(target: target)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        presentCamera(target: target)
                    } else {
                        permissionMessage = "Debes habilitar el acceso a camara para continuar."
                        showPermissionAlert = true
                    }
                }
            }
        default:
            permissionMessage = "La camara esta deshabilitada para esta app."
            showPermissionAlert = true
        }
    }

    private func presentCamera(target: CameraTarget) {
        switch target {
        case .document:
            showDocumentCamera = true
        case .selfie:
            showSelfieCamera = true
        }
    }
}

private struct CartKycImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CartKycImagePicker

        init(parent: CartKycImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if sourceType == .camera && UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
