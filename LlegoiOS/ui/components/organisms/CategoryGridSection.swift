import SwiftUI

struct CategoryGridSection: View {
    // Usando exactamente las mismas categorías que SemicircularSlider
    let categories = [
        ("Restaurantes", "italiana"),
        ("Mercados", "platos_fuertes"),
        ("Farmacias", "vegetariana"),
        ("Moedas", "batidos_y_cocteles"),
        ("Promoções", "bebidas_enlatadas"),
        ("Bebidas", "botellas"),
        ("Cupons", "italiana"),
        ("Gourmet", "platos_fuertes")
    ]

    var onCategoryTap: ((String) -> Void)? = nil

    private let columnSpacing: CGFloat = 12
    private let rowSpacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 20

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: columnSpacing, alignment: .center),
            count: 4
        )
    }

    var body: some View {
        LazyVGrid(
            columns: columns,
            alignment: .center,
            spacing: rowSpacing
        ) {
            ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                CategoryGridItem(
                    title: category.0,
                    imageName: category.1
                )
                .onTapGesture {
                    onCategoryTap?(category.0)
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Category Grid Item
struct CategoryGridItem: View {
    let title: String
    let imageName: String

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(white: 0.95))
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            .overlay(
                VStack(spacing: 6) {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 34, height: 34)

                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
            )
            .aspectRatio(1.35, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        Color.llegoBackground
            .ignoresSafeArea()

        ScrollView {
            CategoryGridSection { category in
                print("Tapped: \(category)")
            }
        }
    }
}
