import SwiftUI

/// Sección para gestionar modelos 3D descargados en ProfileView
struct DownloadedModelsSection: View {
    @ObservedObject private var configManager = BusinessTypeConfigManager.shared
    @State private var showingDeleteConfirmation = false
    @State private var typeToDelete: BusinessTypeConfig?
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Image(systemName: "cube.box.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
                
                Text("Modelos 3D Descargados")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
                
                Spacer()
                
                // Tamaño total
                Text(formattedSize)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            let downloadedTypes = configManager.getDownloadedTypes()
            
            if downloadedTypes.isEmpty {
                // Estado vacío
                emptyState
            } else {
                // Lista de modelos descargados
                VStack(spacing: 0) {
                    ForEach(Array(downloadedTypes.enumerated()), id: \.element.id) { index, config in
                        downloadedModelRow(config, isLast: index == downloadedTypes.count - 1)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.06), lineWidth: 1)
                )
            }
        }
        .confirmationDialog(
            "¿Eliminar modelo?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let config = typeToDelete {
                    withAnimation {
                        configManager.deleteDownloadedModel(for: config)
                    }
                }
                typeToDelete = nil
            }
            Button("Cancelar", role: .cancel) {
                typeToDelete = nil
            }
        } message: {
            if let config = typeToDelete {
                Text("Se eliminará el modelo 3D de \(config.name). Podrás descargarlo de nuevo cuando lo necesites.")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No hay modelos descargados")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
            
            Text("Los modelos de nuevas categorías se descargarán automáticamente")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
    
    private func downloadedModelRow(_ config: BusinessTypeConfig, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Icono del tipo
                ZStack {
                    Circle()
                        .fill(config.glowSwiftUIColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: config.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(config.glowSwiftUIColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                    
                    Text(config.model3dFileName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Botón eliminar
                Button(action: {
                    typeToDelete = config
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            
            if !isLast {
                Divider()
                    .padding(.leading, 74)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedSize: String {
        let bytes = configManager.getDownloadedModelsSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Download Progress View
/// Vista de progreso de descarga para mostrar en el carrusel
struct Model3DDownloadOverlay: View {
    let state: Model3DDownloadState
    let config: BusinessTypeConfig
    let onDownload: () -> Void
    
    var body: some View {
        switch state {
        case .notNeeded, .downloaded:
            EmptyView()
            
        case .notDownloaded:
            downloadButton
            
        case .downloading(let progress):
            downloadingView(progress: progress)
            
        case .failed(let message):
            failedView(message: message)
        }
    }
    
    private var downloadButton: some View {
        VStack(spacing: 16) {
            Button(action: onDownload) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Descargar modelo 3D")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(DownloadScaleButtonStyle())
            
            Text("Toca para descargar")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.4)
                .blur(radius: 1)
        )
    }
    
    private func downloadingView(progress: Double) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 70, height: 70)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Descargando...")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.4)
                .blur(radius: 1)
        )
    }
    
    private func failedView(message: String) -> some View {
        VStack(spacing: 16) {
            Button(action: onDownload) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("Reintentar descarga")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(DownloadScaleButtonStyle())
            
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black.opacity(0.5)
                .blur(radius: 1)
        )
    }
}

// MARK: - Download Scale Button Style
struct DownloadScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    VStack {
        DownloadedModelsSection()
            .padding()
    }
    .background(Color.llegoBackground)
}
