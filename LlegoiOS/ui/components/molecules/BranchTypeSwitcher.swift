//
//  BranchTypeSwitcher.swift
//  LlegoiOS
//
//  Selector de tipo de negocio (restaurante, tienda, dulcería, perfumería)
//  para el modo simple: sustituye al carrusel 3D del Home como forma de
//  cambiar de categoría, directamente sobre el feed.
//
//  A diferencia de la fila de categorías de abajo (CategoryChip, cápsulas
//  pequeñas con el acento global), aquí cada tipo es una tarjeta más grande,
//  con su propio color y una foto que lo representa.
//

import SwiftUI
import UIKit

// MARK: - Métricas

private enum BranchTypeCardMetrics {
    static let cardCornerRadius: CGFloat = 22
    static let compactCardCornerRadius: CGFloat = 17
    static let photoSize: CGFloat = 48
    static let photoCornerRadius: CGFloat = 14
}

private typealias Metrics = BranchTypeCardMetrics

struct BranchTypeSwitcher: View {
    /// Al hacer scroll la fila se encoge: la foto se pliega y queda solo la
    /// píldora de color, para no comerse la pantalla estando fijada arriba.
    var isCompact: Bool = false

    @ObservedObject private var branchTypeManager = BranchTypeManager.shared
    @ObservedObject private var configManager = BusinessTypeConfigManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var cardNamespace

    // MARK: - Opciones

    private struct Option: Identifiable {
        /// Índice de categoría: también alimenta la paleta del gradiente.
        let id: Int
        let type: BranchType
        let name: String
        let icon: String
    }

    /// Usa los tipos dinámicos del backend cuando existen; si no, los cuatro fijos.
    private var options: [Option] {
        if !configManager.businessTypes.isEmpty {
            let mapped = configManager.businessTypes.enumerated().compactMap { index, config -> Option? in
                guard let type = BranchType(rawValue: config.key.lowercased()) else { return nil }
                return Option(id: index, type: type, name: config.name, icon: config.icon)
            }
            if !mapped.isEmpty { return mapped }
        }

        return [
            Option(id: 0, type: .restaurante, name: "Restaurantes", icon: "fork.knife"),
            Option(id: 1, type: .tienda, name: "Tiendas", icon: "cart.fill"),
            Option(id: 2, type: .dulceria, name: "Dulcería", icon: "birthday.cake.fill"),
            Option(id: 3, type: .perfumeria, name: "Perfumería", icon: "drop.fill")
        ]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Las tarjetas viven dentro de un contenedor de Liquid Glass para que
            // el cristal de las vecinas se mezcle en vez de pintarse por separado.
            BranchTypeGlassContainer(spacing: 10) {
                HStack(spacing: isCompact ? 8 : 10) {
                    ForEach(options) { option in
                        optionCard(option)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isCompact ? 6 : 10)
        }
        .scrollClipDisabled()
    }

    // MARK: - Tarjeta

    private func optionCard(_ option: Option) -> some View {
        let isSelected = branchTypeManager.selectedType == option.type
        // Cada tipo lleva su color, no el acento global: así la fila se lee
        // como cuatro mundos distintos y no como un único filtro.
        let accent = gradientManager.accentColor(at: option.id)
        let palette = gradientManager.gradientPalette(at: option.id)

        return Button {
            select(option)
        } label: {
            HStack(spacing: isCompact ? 0 : 11) {
                photo(for: option, accent: accent, isSelected: isSelected)

                Text(option.name)
                    .font(.system(size: isCompact ? 14 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color.primary.opacity(0.85))
                    .fixedSize()
            }
            .padding(.leading, isCompact ? 14 : 8)
            .padding(.trailing, isCompact ? 14 : 18)
            .padding(.vertical, isCompact ? 9 : 8)
            .modifier(
                BranchTypeCardGlassModifier(
                    accent: accent,
                    palette: palette,
                    isSelected: isSelected,
                    isCompact: isCompact,
                    colorScheme: colorScheme,
                    glassID: option.id,
                    namespace: cardNamespace
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: isCompact ? Metrics.compactCardCornerRadius : Metrics.cardCornerRadius,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Foto

    @ViewBuilder
    private func photo(for option: Option, accent: Color, isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Metrics.photoCornerRadius, style: .continuous)

        ZStack {
            if let image = assetImage(for: option.type) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // Tipos dinámicos sin foto local: el icono sobre su propio color.
                accent.opacity(0.9)
                Image(systemName: option.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: Metrics.photoSize, height: Metrics.photoSize)
        .clipShape(shape)
        .overlay(
            shape.stroke(
                isSelected ? Color.white.opacity(0.55) : accent.opacity(0.25),
                lineWidth: 1
            )
        )
        .saturation(isSelected ? 1.0 : 0.85)
        .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.08), radius: 4, x: 0, y: 2)
        // En compacto la foto se pliega hacia dentro en vez de desaparecer de
        // golpe: se encoge, se desvanece y deja de ocupar ancho.
        .scaleEffect(isCompact ? 0.4 : 1, anchor: .leading)
        .opacity(isCompact ? 0 : 1)
        .frame(width: isCompact ? 0 : Metrics.photoSize, height: isCompact ? 20 : Metrics.photoSize)
        // Plegada ocupa 0 de ancho pero su contenido sigue desbordando hacia los
        // lados: sin esto se comía los toques del borde de la tarjeta vecina.
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Foto local del tipo de negocio, si existe en el catálogo de assets.
    private func assetImage(for type: BranchType) -> UIImage? {
        UIImage(named: "branchtype_\(type.rawValue)")
    }

    // MARK: - Acción

    private func select(_ option: Option) {
        guard branchTypeManager.selectedType != option.type else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            branchTypeManager.setType(option.type)
            // Mantiene el color de acento y el gradiente en sintonía con la categoría,
            // igual que hace el carrusel del Home en modo elegante.
            gradientManager.setCategoryIndex(option.id)
        }
    }
}

// MARK: - Liquid Glass

/// Agrupa las tarjetas en un `GlassEffectContainer` (iOS 26+) para que el cristal
/// de las que están juntas se funda, en vez de renderizarse aislado por tarjeta.
private struct BranchTypeGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

/// Fondo de la tarjeta: Liquid Glass teñido con el color propio del tipo de
/// negocio en iOS 26+, y el degradado sólido de siempre como respaldo.
private struct BranchTypeCardGlassModifier: ViewModifier {
    let accent: Color
    let palette: (dark: Color, medium: Color, light: Color, veryLight: Color)
    let isSelected: Bool
    let isCompact: Bool
    let colorScheme: ColorScheme
    let glassID: Int
    let namespace: Namespace.ID

    private var cornerRadius: CGFloat {
        isCompact ? Metrics.compactCardCornerRadius : Metrics.cardCornerRadius
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Tinte del cristal: fuerte cuando está activo, apenas un velo de color
    /// cuando no, para que cada tipo se siga reconociendo por su color.
    private var tint: Color {
        if isSelected {
            return accent.opacity(0.80)
        }
        return accent.opacity(colorScheme == .dark ? 0.22 : 0.14)
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular.tint(tint).interactive(),
                    in: .rect(cornerRadius: cornerRadius, style: .continuous)
                )
                .glassEffectID(glassID, in: namespace)
                // Mantiene la profundidad del degradado original sin tapar el cristal.
                .overlay {
                    if isSelected {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, palette.dark.opacity(0.30)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .allowsHitTesting(false)
                    }
                }
                .shadow(color: accent.opacity(isSelected ? 0.28 : 0.0), radius: 10, x: 0, y: 5)
        } else {
            content
                .background(fallbackBackground)
        }
    }

    @ViewBuilder
    private var fallbackBackground: some View {
        if isSelected {
            shape
                .fill(
                    LinearGradient(
                        colors: [accent, palette.dark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: accent.opacity(0.35), radius: 10, x: 0, y: 5)
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.fill(accent.opacity(colorScheme == .dark ? 0.16 : 0.09)))
                .overlay(shape.stroke(accent.opacity(0.20), lineWidth: 1))
        }
    }
}
