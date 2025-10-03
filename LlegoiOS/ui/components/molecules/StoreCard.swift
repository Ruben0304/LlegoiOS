import SwiftUI

struct StoreCard: View {
    let storeName: String
    let etaMinutes: Int
    let logoUrl: String
    let bannerUrl: String
    let address: String?
    let rating: Double?
    let size: StoreCardSize

    init(storeName: String, etaMinutes: Int, logoUrl: String, bannerUrl: String, address: String? = nil, rating: Double? = nil, size: StoreCardSize = .medium) {
        self.storeName = storeName
        self.etaMinutes = etaMinutes
        self.logoUrl = logoUrl
        self.bannerUrl = bannerUrl
        self.address = address
        self.rating = rating
        self.size = size
    }

    var body: some View {
        switch size {
        case .medium:
            mediumCard
        case .expanded:
            expandedCard
        }
    }

    // MARK: - Medium Card (for horizontal scroll)
    private var mediumCard: some View {
        let cardWidth: CGFloat = 250
        let cardHeight: CGFloat = 190
        let bannerHeight: CGFloat = 100
        let logoSize: CGFloat = 56
        let padding: CGFloat = 12
        let nameFontSize: CGFloat = 16
        let etaFontSize: CGFloat = 14
        let cornerRadius: CGFloat = 16
        let logoOffset = logoSize / 2

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Banner Image
                AsyncImage(url: URL(string: bannerUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                }
                .frame(height: bannerHeight)
                .clipped()

                // Store Info Row - full width below logo
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeName)
                        .font(.system(size: nameFontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 4) {
                        Text("⚡")
                            .font(.system(size: etaFontSize))

                        Text("In \(etaMinutes) minutes")
                            .font(.system(size: etaFontSize, weight: .regular, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, padding)
                .padding(.top, logoOffset + (padding * 0.5))
                .padding(.bottom, padding * 1.2)
            }
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            // Store Logo - overlapping design
            AsyncImage(url: URL(string: logoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.white)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                    )
            }
            .frame(width: logoSize, height: logoSize)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
            .offset(x: padding, y: bannerHeight - logoOffset)
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Expanded Card (for search full width)
    private var expandedCard: some View {
        let bannerHeight: CGFloat = 120
        let logoSize: CGFloat = 64
        let padding: CGFloat = 16
        let nameFontSize: CGFloat = 18
        let detailFontSize: CGFloat = 14
        let cornerRadius: CGFloat = 18
        let logoOffset = logoSize / 2

        return ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                // Banner Image
                AsyncImage(url: URL(string: bannerUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(height: bannerHeight)
                .clipped()

                // Store Info - expanded version with left/right layout
                VStack(alignment: .leading, spacing: 10) {
                    // Store Name - Left aligned
                    Text(storeName)
                        .font(.system(size: nameFontSize, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Address and Rating Row - Distributed
                    HStack(alignment: .center, spacing: 12) {
                        // Address - Left side, flexible width
                        if let address = address {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.llegoTertiary)

                                Text(address)
                                    .font(.system(size: detailFontSize, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer(minLength: 8)

                        // Rating - Right side, fixed width
                        if let rating = rating {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.yellow)

                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: detailFontSize, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            .fixedSize()
                        }
                    }

                    // ETA - Left aligned
                    HStack(spacing: 4) {
                        Text("⚡")
                            .font(.system(size: detailFontSize))

                        Text("\(etaMinutes) min")
                            .font(.system(size: detailFontSize, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, padding)
                .padding(.top, logoOffset + (padding * 0.5))
                .padding(.bottom, padding)
            }
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            // Store Logo - overlapping design
            AsyncImage(url: URL(string: logoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.white)
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(width: logoSize, height: logoSize)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 3)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 3)
            .offset(x: padding, y: bannerHeight - logoOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
    }
}

struct StoreCard_Previews: PreviewProvider {
    static var previews: some View {
        StoreCard(
            storeName: "Fresh Market",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center"
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}