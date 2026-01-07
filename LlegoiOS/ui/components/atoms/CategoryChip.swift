import SwiftUI

/// Chip de categoría con diseño destacado y animación de gradiente
/// Usado en: ProductListView para filtrado de categorías
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let isFeatured: Bool
    let onTap: () -> Void

    @State private var gradientAngle: Angle = .degrees(0)

    var body: some View {
        let accentColor = Color.llegoPrimary
        let foregroundColor: Color = isSelected ? accentColor : .onSurfaceColor
        let deepGold = Color(red: 0.48, green: 0.36, blue: 0.12)
        let premiumStroke = LinearGradient(
            colors: [Color.llegoSecondary.opacity(0.9), deepGold],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark" : icon)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                    .foregroundColor(foregroundColor)
                Text(title)
                    .fontWeight(.semibold)
                    .font(.system(size: 14))
                    .foregroundColor(foregroundColor)
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .clipShape(Capsule())
        .compositingGroup()
        .tint(.white)
        .background {
            if isFeatured {
                Capsule()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoTertiary,
                                Color.llegoButton,
                                deepGold,
                                Color.llegoPrimary
                            ]),
                            center: .center,
                            angle: gradientAngle
                        )
                    )
                    .overlay(Capsule().fill(Color.black.opacity(0.28)))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: gradientAngle)
            }
        }
        .overlay {
            if isSelected {
                Capsule()
                    .stroke(premiumStroke, lineWidth: 1.2)
            }
        }
        .onAppear {
            if isFeatured {
                gradientAngle = .degrees(360)
            }
        }
    }
}
