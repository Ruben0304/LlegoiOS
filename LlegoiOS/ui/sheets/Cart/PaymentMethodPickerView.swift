import SwiftUI

// MARK: - Payment Method Picker View
struct PaymentMethodPickerView: View {
    let paymentMethods: [PaymentMethod]
    @Binding var selectedMethod: PaymentMethod?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        //                        header
                        paymentList
                    }
                }
            }
            .navigationTitle("Métodos de Pago")
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
            Text("Métodos de pago")
                .scaledFont(size: 22, weight: .bold, design: .rounded, relativeTo: .title2)
                .foregroundColor(.primary)

            Text(
                "Elige la opción que prefieras. Mostramos sólo la información esencial para que la decisión sea rápida."
            )
            .font(.system(size: 14, weight: .medium))
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
                        .scaledFont(size: 16, weight: .semibold, relativeTo: .body)
                        .foregroundColor(.primary)

                    Text("Por favor, intenta de nuevo más tarde")
                        .scaledFont(size: 14, relativeTo: .subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(enumeratedPaymentMethods, id: \.element.id) { pair in
                        let index = pair.offset
                        let method = pair.element
                        PaymentMethodRow(
                            method: method,
                            isSelected: selectedMethod?.id == method.id,
                            onTap: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedMethod = method
                                }
                                // Cerrar después de seleccionar
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    dismiss()
                                }
                            },
                            animationDelay: Double(index) * 0.05
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var enumeratedPaymentMethods: [(offset: Int, element: PaymentMethod)] {
        Array(paymentMethods.enumerated())
    }
}
