import SwiftUI

struct CategoriesView: View {
    // Mismas categorías que SemicircularSlider
    let categories = [
        ("Italiana", "italiana"),
        ("Platos Fuertes", "platos_fuertes"),
        ("Vegetariana", "vegetariana"),
        ("Batidos y Cócteles", "batidos_y_cocteles"),
        ("Bebidas Enlatadas", "bebidas_enlatadas"),
        ("Botellas", "botellas")
    ]

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    @State private var navigateToShop = false
    @State private var selectedCategory: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(categories.indices, id: \.self) { index in
                        CategoryCard(
                            name: categories[index].0,
                            imageName: categories[index].1,
                            onTap: {
                                selectedCategory = categories[index].0
                                navigateToShop = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color.llegoBackground.ignoresSafeArea())
            .navigationTitle("Categorías")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $navigateToShop) {
            NavigationView {
                ShopView(category: selectedCategory)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct CategoryCard: View {
    let name: String
    let imageName: String
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Card principal
            VStack(alignment: .leading, spacing: 12) {
                Spacer()

                // Texto de categoría
                Text(name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                // Botón "Ver"
                Button(action: {
                    // Feedback háptico
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                    // Acción al presionar Ver
                    onTap()
                }) {
                    HStack(spacing: 6) {
                        Text("Ver")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.llegoPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white)
                            .shadow(
                                color: Color.black.opacity(0.15),
                                radius: 6,
                                x: 0,
                                y: 3
                            )
                    )
                }
                .padding(.leading, 16)
                .padding(.bottom, 16)
            }
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoPrimary.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: Color.llegoPrimary.opacity(0.3),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
            )

            // Imagen que se sale del card (arriba a la derecha)
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 95, height: 95)
                .offset(x: 15, y: -15)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

#Preview {
    CategoriesView()
}
