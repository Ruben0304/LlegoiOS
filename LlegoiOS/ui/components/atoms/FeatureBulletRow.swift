import SwiftUI

/// Fila de característica con icono de corona y texto con formato
/// Usado en: PlansAndPricingView para listar beneficios de planes
struct FeatureBulletRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.96, green: 0.74, blue: 0.18))
                .frame(width: 26, height: 26, alignment: .top)

            (
                Text(title).fontWeight(.bold)
                + Text(" " + description)
            )
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.black.opacity(0.8))
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}
