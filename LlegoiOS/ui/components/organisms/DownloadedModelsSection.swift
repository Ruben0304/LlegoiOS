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
                    .scaledFont(size: 20, weight: .semibold, relativeTo: .title3)
                    .foregroundColor(.llegoPrimary)
                
                Text("Modelos 3D Descargados")
                    .scaledFont(size: 18, weight: .bold, design: .rounded, relativeTo: .title3)
                    .foregroundColor(.llegoPrimary)
                
                Spacer()
                
                // Tamaño total
                Text(formattedSize)
                    .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
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
                .scaledFont(size: 32, weight: .light, relativeTo: .largeTitle)
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No hay modelos descargados")
                .scaledFont(size: 15, weight: .medium, relativeTo: .subheadline)
                .foregroundColor(.gray)
            
            Text("Los modelos de nuevas categorías se descargarán automáticamente")
                .scaledFont(size: 13, relativeTo: .footnote)
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
                        .scaledFont(size: 18, weight: .semibold, relativeTo: .title3)
                        .foregroundColor(config.glowSwiftUIColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.name)
                        .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                        .foregroundColor(.llegoPrimary)
                    
                    Text(config.model3dFileName)
                        .scaledFont(size: 13, weight: .medium, relativeTo: .footnote)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Botón eliminar
                Button(action: {
                    typeToDelete = config
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .scaledFont(size: 16, weight: .medium, relativeTo: .body)
                        .foregroundColor(.red.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Eliminar modelo descargado")
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
                            .scaledFont(size: 36, weight: .medium, relativeTo: .largeTitle)
                            .foregroundColor(.white)
                    }
                    
                    Text("Descargar modelo 3D")
                        .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(DownloadScaleButtonStyle())
            
            Text("Toca para descargar")
                .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
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
                    .scaledFont(size: 16, weight: .bold, relativeTo: .body)
                    .foregroundColor(.white)
            }
            
            Text("Descargando...")
                .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
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
                            .scaledFont(size: 36, weight: .medium, relativeTo: .largeTitle)
                            .foregroundColor(.white)
                    }
                    
                    Text("Reintentar descarga")
                        .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(DownloadScaleButtonStyle())
            
            Text(message)
                .scaledFont(size: 11, weight: .medium, relativeTo: .caption)
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
