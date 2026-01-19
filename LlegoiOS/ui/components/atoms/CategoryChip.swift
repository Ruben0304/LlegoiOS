import SwiftUI

/// Chip de categoría con diseño destacado y animación de gradiente
/// Usado en: ProductListView para filtrado de categorías
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isFeatured: Bool
    let onTap: () -> Void
    var accentColor: Color = Color.llegoPrimary

    @State private var gradientAngle: Angle = .degrees(0)
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark" : icon)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                Text(title)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .clipShape(Capsule())
        .compositingGroup()
        .tint(accentColor)
        .overlay {
            if isSelected {
                Capsule()
                    .stroke(Color.white, lineWidth: 1.2)
            }
        }
    }
}
