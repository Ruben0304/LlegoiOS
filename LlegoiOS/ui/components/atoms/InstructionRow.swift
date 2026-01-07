import SwiftUI

/// Fila de instrucción numerada con icono circular
/// Usado en: CartView para mostrar instrucciones de pago
struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.llegoPrimary.opacity(0.12))
                    .frame(width: 26, height: 26)

                Text(number)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
            }

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
