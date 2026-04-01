import AVFoundation
import Combine
import CryptoKit
import Foundation
import SwiftUI
import UIKit

struct CashKycFlowContext: Identifiable {
    let id: String
    let orderId: String
    let paymentAttempt: PaymentAttemptModel
    let paymentMethodDisplayName: String
    let createdOrder: CreatedOrder?
}

enum CashKycUIState: Equatable {
    case idle
    case loadingPolicy
    case cashAvailableWithoutCoverage
    case requiresKyc
    case capturingEvidence
    case submitting
    case waitingResult
    case approved
    case rejected
    case retryableError
    case hardError
    case expired
}

@MainActor
final class CashKycFlowViewModel: ObservableObject {
    @Published var state: CashKycUIState = .idle
    @Published var title: String = "Verificación para efectivo"
    @Published var message: String = "Estamos preparando la verificación."
    @Published var documentImage: UIImage?
    @Published var selfieImage: UIImage?
    @Published var isPolling: Bool = false

    let context: CashKycFlowContext
    private let paymentRepository = PaymentRepository()
    private let authManager = AuthManager.shared
    private var currentVerificationId: String?

    init(context: CashKycFlowContext) {
        self.context = context
    }

    var canSubmitEvidence: Bool {
        documentImage != nil && selfieImage != nil
    }

    func start() {
        Task {
            await refreshPolicyAndStatus()
        }
    }

    func refreshPolicyAndStatus() async {
        guard let jwt = authManager.getAccessToken() else {
            setState(
                .hardError,
                title: "Sesión no válida",
                message: "Debes iniciar sesión nuevamente para verificar tu pago."
            )
            return
        }

        setState(
            .loadingPolicy, title: "Verificando requisitos",
            message: "Consultando política de pago en efectivo...")

        do {
            let policy = try await paymentRepository.cashKycPolicy(
                orderId: context.orderId, jwt: jwt)
            if policy.allowCash {
                _ = applyDecision(policy)
                return
            }

            let status = try await paymentRepository.cashKycStatus(
                paymentAttemptId: context.paymentAttempt.id,
                jwt: jwt
            )
            _ = applyDecision(status)
        } catch {
            setState(
                .hardError,
                title: "No se pudo validar el pago en efectivo",
                message: "Revisa tu conexión e inténtalo nuevamente."
            )
        }
    }

    func submitEvidence() {
        guard canSubmitEvidence else {
            setState(
                .capturingEvidence,
                title: "Falta evidencia",
                message: "Debes capturar el documento y la selfie antes de continuar."
            )
            return
        }
        guard let documentData = documentImage?.jpegData(compressionQuality: 0.8),
            let selfieData = selfieImage?.jpegData(compressionQuality: 0.8)
        else {
            setState(
                .retryableError,
                title: "No se pudo preparar la evidencia",
                message: "Intenta tomar las fotos nuevamente."
            )
            return
        }
        guard let jwt = authManager.getAccessToken() else {
            setState(
                .hardError,
                title: "Sesión no válida",
                message: "Debes iniciar sesión nuevamente para verificar tu pago."
            )
            return
        }

        setState(
            .submitting, title: "Enviando evidencia",
            message: "Estamos procesando tu documento y selfie...")

        Task {
            do {
                let result = try await paymentRepository.startCashKycEvaluation(
                    paymentAttemptId: context.paymentAttempt.id,
                    identityDocumentFrontBase64: documentData.base64EncodedString(),
                    selfieLiveBase64: selfieData.base64EncodedString(),
                    deviceContext: buildDeviceContext(),
                    transactionContext: buildTransactionContext(),
                    jwt: jwt
                )
                currentVerificationId = result.verificationId
                if applyDecision(result) { return }
                await pollStatus()
            } catch {
                setState(
                    .retryableError,
                    title: "No se pudo enviar la evidencia",
                    message: "Intenta nuevamente o cambia de método de pago."
                )
            }
        }
    }

    func retry() {
        guard let verificationId = currentVerificationId else {
            Task { await refreshPolicyAndStatus() }
            return
        }
        guard let jwt = authManager.getAccessToken() else {
            setState(
                .hardError,
                title: "Sesión no válida",
                message: "Debes iniciar sesión nuevamente para verificar tu pago."
            )
            return
        }

        setState(
            .submitting, title: "Reintentando verificación",
            message: "Estamos enviando el reintento al servidor...")
        Task {
            do {
                let result = try await paymentRepository.retryCashKycEvaluation(
                    verificationId: verificationId,
                    jwt: jwt
                )
                if applyDecision(result) { return }
                await pollStatus()
            } catch {
                setState(
                    .retryableError,
                    title: "No fue posible reintentar",
                    message: "Puedes capturar de nuevo la evidencia o elegir otro método."
                )
            }
        }
    }

    func clearEvidence() {
        documentImage = nil
        selfieImage = nil
    }

    private func pollStatus() async {
        guard let jwt = authManager.getAccessToken() else { return }
        isPolling = true
        defer { isPolling = false }

        for _ in 0..<8 {
            do {
                let status = try await paymentRepository.cashKycStatus(
                    paymentAttemptId: context.paymentAttempt.id,
                    jwt: jwt
                )
                currentVerificationId = status.verificationId ?? currentVerificationId
                if applyDecision(status) {
                    return
                }
            } catch {
                break
            }

            try? await Task.sleep(nanoseconds: 3_000_000_000)
        }

        setState(
            .retryableError,
            title: "Verificación en espera",
            message: "No recibimos una respuesta final. Puedes reintentar o elegir otro método."
        )
    }

    @discardableResult
    private func applyDecision(_ decision: CashKycDecisionSnapshot) -> Bool {
        currentVerificationId = decision.verificationId ?? currentVerificationId

        if decision.allowCash {
            if decision.appCoversCash {
                setState(
                    .approved, title: "Efectivo habilitado",
                    message: "Tu verificación fue aprobada. Puedes continuar.")
            } else {
                setState(
                    .cashAvailableWithoutCoverage,
                    title: "Efectivo habilitado",
                    message:
                        "Este pago en efectivo está permitido, pero no tiene cobertura de la app."
                )
            }
            return true
        }

        switch decision.kycEvalStatus {
        case .pendingEvidence:
            setState(
                .requiresKyc,
                title: "Verificación requerida",
                message:
                    "Para este negocio necesitas verificar identidad antes de pagar en efectivo."
            )
            return true
        case .submitted:
            setState(
                .waitingResult, title: "Verificación en progreso",
                message: "Estamos evaluando tu evidencia.")
            return false
        case .approved:
            setState(
                .approved, title: "Efectivo habilitado",
                message: "Tu verificación fue aprobada. Puedes continuar.")
            return true
        case .rejected:
            setState(
                .rejected,
                title: "No fue posible aprobar la verificación",
                message:
                    "No puedes continuar con efectivo para este pedido. Elige otro método de pago."
            )
            return true
        case .needsReview, .insufficientData, .error:
            setState(
                .retryableError,
                title: "Necesitamos una nueva verificación",
                message: preferredKycMessage(
                    decision,
                    fallback: "Puedes reintentar la verificación o cambiar el método de pago."
                )
            )
            return true
        case .expired:
            setState(
                .expired,
                title: "Verificación expirada",
                message: "Debes capturar nuevamente documento y selfie para continuar en efectivo."
            )
            return true
        case .notRequired:
            setState(
                .cashAvailableWithoutCoverage,
                title: "Efectivo habilitado",
                message: "Este pago en efectivo está permitido sin verificación y sin cobertura."
            )
            return true
        case .unknown:
            setState(
                .hardError,
                title: "Estado no reconocido",
                message: "No se pudo validar el pago en efectivo con seguridad. Elige otro método."
            )
            return true
        }
    }

    private func setState(_ state: CashKycUIState, title: String, message: String) {
        self.state = state
        self.title = title
        self.message = message
        if state == .requiresKyc || state == .expired || state == .retryableError {
            if documentImage != nil || selfieImage != nil {
                self.state = .capturingEvidence
            }
        }
    }

    private func preferredKycMessage(_ decision: CashKycDecisionSnapshot, fallback: String) -> String {
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

    private func buildTransactionContext() -> [String: Any] {
        let formatter = ISO8601DateFormatter()
        return [
            "orderId": context.orderId,
            "paymentAttemptId": context.paymentAttempt.id,
            "currency": context.paymentAttempt.currency,
            "totalAmount": context.paymentAttempt.totalAmount,
            "paymentMethod": "cash",
            "timestamp": formatter.string(from: Date()),
        ]
    }
}

struct CashKycFlowSheet: View {
    let context: CashKycFlowContext
    let onApproved: () -> Void
    let onBlocked: (_ message: String, _ suggestChangeMethod: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CashKycFlowViewModel
    @State private var showingDocumentCamera = false
    @State private var showingSelfieCamera = false
    @State private var showCameraPermissionAlert = false
    @State private var cameraPermissionMessage = ""

    init(
        context: CashKycFlowContext,
        onApproved: @escaping () -> Void,
        onBlocked: @escaping (_ message: String, _ suggestChangeMethod: Bool) -> Void
    ) {
        self.context = context
        self.onApproved = onApproved
        self.onBlocked = onBlocked
        _viewModel = StateObject(wrappedValue: CashKycFlowViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.title)
                        .font(.system(size: 22, weight: .bold))
                    Text(viewModel.message)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)

                    statusPanel
                    capturePanel
                    actionsPanel
                }
                .padding(20)
            }
            .navigationTitle("KYC efectivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        viewModel.clearEvidence()
                        dismiss()
                        onBlocked("Pago en efectivo cancelado.", false)
                    }
                }
            }
            .sheet(isPresented: $showingDocumentCamera) {
                KycCameraPicker(image: $viewModel.documentImage)
            }
            .sheet(isPresented: $showingSelfieCamera) {
                KycCameraPicker(image: $viewModel.selfieImage)
            }
            .alert("Permiso de cámara", isPresented: $showCameraPermissionAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(cameraPermissionMessage)
            }
            .onAppear {
                viewModel.start()
            }
        }
    }

    @ViewBuilder
    private var statusPanel: some View {
        switch viewModel.state {
        case .loadingPolicy, .submitting, .waitingResult:
            HStack(spacing: 10) {
                ProgressView().tint(.blue)
                Text(viewModel.state == .waitingResult ? "Esperando resultado..." : "Procesando...")
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        case .approved:
            stateBadge("Aprobado", color: .green)
        case .cashAvailableWithoutCoverage:
            stateBadge("Efectivo permitido sin cobertura", color: .orange)
        case .rejected, .hardError:
            stateBadge("Efectivo bloqueado", color: .red)
        case .retryableError, .expired:
            stateBadge("Requiere nueva verificación", color: .orange)
        default:
            EmptyView()
        }
    }

    private func stateBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var capturePanel: some View {
        let needsCapture =
            viewModel.state == .requiresKyc
            || viewModel.state == .capturingEvidence
            || viewModel.state == .expired
            || viewModel.state == .retryableError

        if needsCapture {
            VStack(alignment: .leading, spacing: 10) {
                Text("Evidencia requerida")
                    .font(.system(size: 16, weight: .semibold))
                captureRow(
                    title: "Documento (frente)",
                    isCaptured: viewModel.documentImage != nil,
                    buttonTitle: "Capturar documento"
                ) {
                    openCamera(for: .document)
                }
                captureRow(
                    title: "Selfie en vivo",
                    isCaptured: viewModel.selfieImage != nil,
                    buttonTitle: "Capturar selfie"
                ) {
                    openCamera(for: .selfie)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func captureRow(
        title: String,
        isCaptured: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isCaptured ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCaptured ? .green : .secondary)
            Text(title)
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Button(buttonTitle, action: action)
                .font(.system(size: 13, weight: .semibold))
        }
    }

    @ViewBuilder
    private var actionsPanel: some View {
        VStack(spacing: 10) {
            switch viewModel.state {
            case .requiresKyc, .capturingEvidence, .expired:
                Button("Enviar verificación") {
                    viewModel.submitEvidence()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmitEvidence)
            case .retryableError:
                Button("Reintentar verificación") {
                    if viewModel.canSubmitEvidence {
                        viewModel.submitEvidence()
                    } else {
                        viewModel.retry()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Usar otro método de pago") {
                    dismiss()
                    onBlocked("Pago en efectivo bloqueado. Selecciona otro método de pago.", true)
                }
                .buttonStyle(.bordered)
            case .waitingResult:
                Button("Actualizar estado") {
                    Task { await viewModel.refreshPolicyAndStatus() }
                }
                .buttonStyle(.borderedProminent)
            case .approved, .cashAvailableWithoutCoverage:
                Button("Continuar con efectivo") {
                    viewModel.clearEvidence()
                    dismiss()
                    onApproved()
                }
                .buttonStyle(.borderedProminent)
            case .rejected, .hardError:
                Button("Usar otro método de pago") {
                    dismiss()
                    onBlocked(
                        "No fue posible continuar con pago en efectivo para este pedido.", true)
                }
                .buttonStyle(.borderedProminent)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private enum CaptureTarget {
        case document
        case selfie
    }

    private func openCamera(for target: CaptureTarget) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            presentCamera(for: target)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        presentCamera(for: target)
                    } else {
                        cameraPermissionMessage =
                            "Debes habilitar el acceso a cámara para verificar tu identidad."
                        showCameraPermissionAlert = true
                    }
                }
            }
        default:
            cameraPermissionMessage =
                "La cámara está deshabilitada para esta app. Actívala en Configuración."
            showCameraPermissionAlert = true
        }
    }

    private func presentCamera(for target: CaptureTarget) {
        switch target {
        case .document:
            showingDocumentCamera = true
        case .selfie:
            showingSelfieCamera = true
        }
    }
}

private struct KycCameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    final class Coordinator: NSObject, UINavigationControllerDelegate,
        UIImagePickerControllerDelegate
    {
        let parent: KycCameraPicker

        init(parent: KycCameraPicker) {
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
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
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
