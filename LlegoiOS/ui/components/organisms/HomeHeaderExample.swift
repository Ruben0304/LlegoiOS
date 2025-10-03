import SwiftUI

struct HomeHeaderExample: View {
    @State private var searchText = ""
    @State private var cartCount = 0

    var body: some View {
        VStack(spacing: 20) {
            // Header con SearchBar y CartButton (estado inicial de HomeScreen)
            HStack(spacing: 8) {
                LlegoSearchBar(
                    text: $searchText,
                    onValueChange: { newValue in
                        print("Búsqueda: \(newValue)")
                    }
                )

                LlegoCartButton(
                    icon: "cart",
                    badgeCount: cartCount > 0 ? cartCount : nil,
                    onClick: {
                        print("Carrito clickeado")
                    }
                )
                .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            // Botones de prueba
            VStack(spacing: 12) {
                Button("Agregar al carrito") {
                    cartCount += 1
                }
                .buttonStyle(.borderedProminent)

                Button("Limpiar carrito") {
                    cartCount = 0
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .background(Color.llegoBackground.ignoresSafeArea())
    }
}

#Preview {
    HomeHeaderExample()
}