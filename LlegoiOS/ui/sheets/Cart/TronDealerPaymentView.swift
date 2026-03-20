import SwiftUI
import CoreImage.CIFilterBuiltins

struct TronDealerPaymentView: View {
    let address: String
    let amount: Double
    let orderId: String
    let isPolling: Bool
    let onDismiss: () -> Void
    
    @StateObject private var gradientManager = GradientStateManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var showCopiedFeedback = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Pagar con USDT")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Red TRON (TRC20)")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Amount
                    VStack(spacing: 8) {
                        Text("Monto a pagar")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.2f", amount)) USDT")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(gradientManager.currentAccentColor)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(gradientManager.currentAccentColor.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    
                    // QR Code
                    VStack(spacing: 12) {
                        if let qrImage = generateQRCode(from: address) {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        }
                        Text("Escanea con tu wallet")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    // Wallet Address
                    VStack(spacing: 12) {
                        Text("Dirección de wallet")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            Text(address)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                                )
                            
                            Button {
                                UIPasteboard.general.string = address
                                showCopiedFeedback = true
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showCopiedFeedback = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                                        .font(.system(size: 16))
                                    Text(showCopiedFeedback ? "¡Copiado!" : "Copiar dirección")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(gradientManager.currentAccentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instrucciones")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            instructionRow(number: "1", text: "Abre tu wallet de TRON (TronLink, Trust Wallet, etc.)")
                            instructionRow(number: "2", text: "Selecciona enviar USDT en red TRON (TRC20)")
                            instructionRow(number: "3", text: "Escanea el QR o copia la dirección")
                            instructionRow(number: "4", text: "Envía exactamente \(String(format: "%.2f", amount)) USDT")
                            instructionRow(number: "5", text: "Espera la confirmación (1-2 minutos)")
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    )
                    .padding(.horizontal, 24)
                    
                    // Warnings
                    VStack(spacing: 10) {
                        warningRow(icon: "exclamationmark.triangle.fill", text: "Asegúrate de usar la red TRON (TRC20)")
                        warningRow(icon: "exclamationmark.triangle.fill", text: "No envíes desde exchanges (usa wallet personal)")
                        warningRow(icon: "exclamationmark.triangle.fill", text: "Envía el monto exacto mostrado arriba")
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // Status
                    if isPolling {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(gradientManager.currentAccentColor)
                            Text("Esperando confirmación del pago...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(gradientManager.currentAccentColor.opacity(0.08))
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 40)
            }
            .background(Color.feedBackground(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        onDismiss()
                    }
                    .foregroundColor(gradientManager.currentAccentColor)
                }
            }
        }
    }
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(gradientManager.currentAccentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func warningRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.orange)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color.adaptiveOnSurface(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}
