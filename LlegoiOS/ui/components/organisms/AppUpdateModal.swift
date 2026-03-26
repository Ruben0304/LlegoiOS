import SwiftUI

struct AppUpdateModal: View {
    @ObservedObject var viewModel: AppUpdateViewModel
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if viewModel.canDismiss {
                        viewModel.dismissOptionalUpdate()
                    }
                }

            // Modal content
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(viewModel.updateType == .maintenance ? Color.orange.opacity(0.15) : Color.llegoPrimary.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: iconName)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(viewModel.updateType == .maintenance ? .orange : .llegoPrimary)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                // Title
                Text(viewModel.updateTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.bottom, 12)

                // Message
                Text(viewModel.updateMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                // Changelog (if available)
                if let changelog = viewModel.changelog, !changelog.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Novedades:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(changelog)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // Buttons
                VStack(spacing: 12) {
                    if viewModel.updateType == .maintenance {
                        // Solo botón de "Entendido" para mantenimiento
                        Button(action: {
                            viewModel.dismissMaintenance()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))

                                Text("Entendido")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.orange)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        // Botones para actualizaciones (required/optional)
                        Button(action: {
                            viewModel.openAppStore()
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))

                                Text(viewModel.updateType == .required ? "Actualizar Ahora" : "Ir al App Store")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                        }
                        .modifier(AppUpdatePrimaryButtonModifier(tint: gradientManager.currentAccentColor))

                        // Cancel button (only for optional updates)
                        if viewModel.canDismiss {
                            Button(action: {
                                viewModel.dismissOptionalUpdate()
                            }) {
                                Text("Más Tarde")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.llegoPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.llegoPrimary.opacity(0.1))
                                    )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }

    private var iconName: String {
        switch viewModel.updateType {
        case .required:
            return "exclamationmark.triangle.fill"
        case .optional:
            return "arrow.down.circle.fill"
        case .maintenance:
            return "wrench.and.screwdriver.fill"
        case .none:
            return "checkmark.circle.fill"
        }
    }
}

private struct AppUpdatePrimaryButtonModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .tint(tint)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint)
                )
                .buttonStyle(ScaleButtonStyle())
        }
    }
}

// MARK: - Preview
#Preview {
    let viewModel = AppUpdateViewModel.shared
    viewModel.updateType = .optional
    viewModel.appConfig = AppConfigData(
        id: "1",
        minVersion: "1.0.0",
        currentVersion: "1.5.0",
        storeUrl: "https://apps.apple.com/app/id123456789",
        maintenanceEnabled: false,
        maintenanceMessage: nil,
        updateMessage: "¡Hemos añadido nuevas características increíbles!",
        changelog: "• Mejoras en el rendimiento\n• Corrección de errores\n• Nueva interfaz de usuario",
        releaseDate: "2025-01-24T00:00:00Z"
    )
    viewModel.showUpdateAlert = true

    return AppUpdateModal(viewModel: viewModel)
}
