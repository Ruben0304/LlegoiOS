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
    var isTinted: Bool = true

    @State private var gradientAngle: Angle = .degrees(0)
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark" : icon)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                    .foregroundColor(isTinted ? .white : .black)
                Text(title)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                    .foregroundColor(isTinted ? .white : .black)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
        }
        .modifier(CategoryChipButtonStyleModifier())
        .buttonBorderShape(.capsule)
        .clipShape(Capsule())
        .compositingGroup()
        .tint(isTinted ? accentColor : .clear)
        .overlay {
            if isSelected {
                Capsule()
                    .stroke(Color.white, lineWidth: 1.2)
            }
        }
    }
}

private struct CategoryChipButtonStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.plain)
        }
    }
}
