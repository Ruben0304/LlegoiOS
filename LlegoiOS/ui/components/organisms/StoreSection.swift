import SwiftUI

struct StoreSection: View {
    let stores: [Store]
    let onSeeMoreTap: () -> Void
    var onStoreTap: ((Store) -> Void)? = nil
    @State private var animationDelay: Double = 0

    init(stores: [Store], onSeeMoreTap: @escaping () -> Void = {}, onStoreTap: ((Store) -> Void)? = nil) {
        self.stores = stores
        self.onSeeMoreTap = onSeeMoreTap
        self.onStoreTap = onStoreTap
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
                LazyHStack(spacing: 8) {
                    ForEach(Array(stores.enumerated()), id: \.element.id) { index, store in
                        Button(action: {
                            onStoreTap?(store)
                        }) {
                            StoreCard(
                                storeName: store.name,
                                etaMinutes: store.etaMinutes,
                                logoUrl: store.logoUrl,
                                bannerUrl: store.bannerUrl,
                                address: store.address,
                                rating: store.rating,
                                size: .medium
                            )
                            .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                            .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                            .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 15)
                            .animation(
                                .easeOut(duration: 0.6)
                                    .delay(Double(index) * 0.05),
                                value: animationDelay
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onAppear {
                    triggerAnimation(for: stores.count)
                }
                .onChange(of: stores.map(\.id)) { _ in
                    triggerAnimation(for: stores.count)
                }
            }
        }
    }

    private func triggerAnimation(for count: Int) {
        animationDelay = 0
        guard count > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animationDelay = Double(count) * 0.1 + 0.1
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
