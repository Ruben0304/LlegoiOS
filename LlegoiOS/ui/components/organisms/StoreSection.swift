import SwiftUI

struct StoreSection: View {
    let stores: [Store]
    let onSeeMoreTap: () -> Void

    init(stores: [Store], onSeeMoreTap: @escaping () -> Void = {}) {
        self.stores = stores
        self.onSeeMoreTap = onSeeMoreTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section Header
            HStack {
                Text("Tiendas cerca de ti")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)

                Spacer()

                Button(action: onSeeMoreTap) {
                    Text("Ver más")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.llegoTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Horizontal Scrolling Store Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stores, id: \.id) { store in
                        StoreCard(
                            storeName: store.name,
                            etaMinutes: store.etaMinutes,
                            logoUrl: store.logoUrl,
                            bannerUrl: store.bannerUrl,
                            address: store.address,
                            rating: store.rating,
                            size: .medium
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
    }
}

struct StoreSection_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStores = [
            Store(
                id: "1",
                name: "Fresh Market",
                etaMinutes: 25,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "2",
                name: "SuperMart Plus",
                etaMinutes: 15,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            ),
            Store(
                id: "3",
                name: "Local Grocery",
                etaMinutes: 30,
                logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
                bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
            )
        ]

        StoreSection(stores: sampleStores)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}