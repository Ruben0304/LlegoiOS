import SwiftUI

/// Indicador de selección circular con checkmark
/// Usado en: PlansAndPricingView para indicar plan seleccionado
struct PlanSelectionIndicator: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: 2)
                .frame(width: 26, height: 26)

            if isSelected {
                Circle()
                    .fill(Color(red: 0.16, green: 0.73, blue: 0.42))
                    .frame(width: 22, height: 22)

                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}
