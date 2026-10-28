import SwiftUI

// MARK: - Payment Method Picker View
struct PaymentMethodPickerView: View {
    let paymentMethods: [PaymentMethod]
    @Binding var selectedMethod: PaymentMethod?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                CartStyle.background(scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        paymentList
                    }
                }
            }
            .navigationTitle("Cómo quieres pagar")
            .tint(CartStyle.ink(scheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton(action: {
                        dismiss()
                    })
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Elige lo que va contigo.")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundColor(.primary)

            Text(
                "Después volverás al resumen para confirmar tu pedido."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var paymentList: some View {
        Group {
            if paymentMethods.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No hay métodos de pago disponibles")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Por favor, intenta de nuevo más tarde")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(paymentMethods) { method in
                        PaymentMethodRow(
                            method: method,
                            isSelected: selectedMethod?.id == method.id,
                            onTap: {
                                selectedMethod = method
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

}
