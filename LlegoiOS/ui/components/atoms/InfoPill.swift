import SwiftUI

/// Píldora de información con icono, valor y etiqueta
/// Usado en: StoreListView para mostrar información de tienda
struct InfoPill: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .scaledFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                    .foregroundColor(iconColor)
                Text(value)
                    .scaledFont(size: 17, weight: .bold, design: .rounded, relativeTo: .body)
                    .foregroundColor(.primary)
            }

            Text(label)
                .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}
