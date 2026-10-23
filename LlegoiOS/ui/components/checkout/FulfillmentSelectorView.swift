import SwiftUI

struct FulfillmentSelectorView: View {
    @Binding var mode: FulfillmentMode
    let pickupEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Método de entrega")
                .scaledFont(size: 15, weight: .semibold, relativeTo: .subheadline)
                .foregroundColor(.primary)

            Picker("Fulfillment", selection: $mode) {
                Text("Entrega").tag(FulfillmentMode.delivery)
                Text("Recogida").tag(FulfillmentMode.pickup)
            }
            .pickerStyle(.segmented)
            .disabled(!pickupEnabled)
            .opacity(pickupEnabled ? 1 : 0.55)

            if !pickupEnabled {
                Text("La recogida en tienda no está disponible para este carrito.")
                    .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
