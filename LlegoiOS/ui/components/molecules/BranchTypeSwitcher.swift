//
//  BranchTypeSwitcher.swift
//  LlegoiOS
//
//  Selector de tipo de negocio (restaurante, tienda, dulcería, perfumería)
//  para el modo simple: sustituye al carrusel 3D del Home como forma de
//  cambiar de categoría, directamente sobre el feed.
//

import SwiftUI
import UIKit

struct BranchTypeSwitcher: View {
    @ObservedObject private var branchTypeManager = BranchTypeManager.shared
    @ObservedObject private var configManager = BusinessTypeConfigManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    @Namespace private var pillNamespace

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
            HStack(spacing: 8) {
                ForEach(options) { option in
                    optionButton(option)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollClipDisabled()
    }

    // MARK: - Pill

    private func optionButton(_ option: Option) -> some View {
        let isSelected = branchTypeManager.selectedType == option.type
        let accent = gradientManager.currentAccentColor

        return Button {
            select(option)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 13, weight: .semibold))

                Text(option.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .fixedSize()
            }
            .foregroundColor(isSelected ? .white : Color.primary.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(accent)
                            .matchedGeometryEffect(id: "branchTypePill", in: pillNamespace)
                            .shadow(color: accent.opacity(0.28), radius: 8, x: 0, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.primary.opacity(0.05))
                    }
                }
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.name)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
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
