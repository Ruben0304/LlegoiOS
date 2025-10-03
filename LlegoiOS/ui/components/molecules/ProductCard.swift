import SwiftUI

struct Product: Identifiable {
    let id: Int
    let name: String
    let shop: String
    let weight: String
    let price: String
    let imageUrl: String
}

struct ImagePositionKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

struct ProductCard: View {
    let product: Product
    @Binding var count: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var onAddToCartAnimation: ((String, CGPoint) -> Void)? = nil

    @State private var imagePosition: CGPoint = .zero

    var body: some View {
        GeometryReader { containerGeometry in
            let cardWidth = containerGeometry.size.width
            let cardHeight = containerGeometry.size.height

            // Calculate proportional sizes based on original 155x290 dimensions
            let scaleFactor = cardWidth / 155.0
            let imageSize = 130 * scaleFactor
            let nameFontSize = 15 * scaleFactor
            let shopFontSize = 12 * scaleFactor
            let priceFontSize = 17 * scaleFactor
            let nameHeight = 40 * scaleFactor
            let horizontalPadding = 10 * scaleFactor
            let topPadding = 10 * scaleFactor
            let spacingAfterImage = 8 * scaleFactor
            let buttonFontSize = 20 * scaleFactor
            let counterFontSize = 16 * scaleFactor
            let buttonSize = 25 * scaleFactor

            VStack(alignment: .center, spacing: 0) {
                // Main content
                VStack(alignment: .center, spacing: 0) {
                    // Product image with cache
                    CachedAsyncImage(
                        url: URL(string: product.imageUrl),
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        },
                        placeholder: {
                            ProgressView()
                                .frame(width: 24 * scaleFactor, height: 24 * scaleFactor)
                        }
                    )
                    .frame(width: imageSize, height: imageSize)
                    .background(
                        GeometryReader { imageGeometry in
                            Color.clear.preference(
                                key: ImagePositionKey.self,
                                value: imageGeometry.frame(in: .global).center
                            )
                        }
                    )

                Spacer().frame(height: spacingAfterImage)

                // Product name with fixed height for 2 lines
                VStack {
                    Text(product.name)
                        .font(.system(size: nameFontSize, weight: .bold, design: .default))
                        .foregroundColor(Color(red: 97/255, green: 97/255, blue: 97/255))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: nameHeight, alignment: .center)
                        .frame(maxWidth: .infinity)
                }

                // Shop name
                Text("(\(product.shop))")
                    .font(.system(size: shopFontSize, weight: .regular, design: .default))
                    .foregroundColor(Color(red: 97/255, green: 97/255, blue: 97/255))
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 2 * scaleFactor)

                // Price
                Text(product.price)
                    .font(.system(size: priceFontSize, weight: .bold, design: .default))
                    .foregroundColor(Color(red: 97/255, green: 97/255, blue: 97/255))
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)

            Spacer()

            // Counter controls at bottom - matching Compose design exactly
            VStack {
                if count == 0 {
                    // Initial state: just "+" symbol without circle
                    Button(action: {
                        onIncrement()
                        print("🔄 Sending position from ProductCard: \(imagePosition)")
                        onAddToCartAnimation?(product.imageUrl, imagePosition)
                    }) {
                        Text("+")
                            .font(.system(size: buttonFontSize, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255)) // onSurface
                            .frame(maxWidth: .infinity)
                            .frame(height: 26 * scaleFactor)
                    }
                    .offset(y: 9 * scaleFactor)
                    .padding(.horizontal, 12 * scaleFactor)
                    .padding(.bottom, 12 * scaleFactor)
                    .background(
                        CounterControlsShape()
                            .fill(Color(red: 236/255, green: 240/255, blue: 233/255)) // surfaceVariant
                    )
                } else {
                    // State with counter and buttons
                    HStack {
                        // Decrement pill button
                        Button(action: onDecrement) {
                            Text("–")
                                .font(.system(size: counterFontSize, weight: .bold, design: .default))
                                .foregroundColor(Color(red: 19/255, green: 45/255, blue: 47/255)) // onSurfaceVariant
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(red: 243/255, green: 243/255, blue: 243/255)) // background
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Count display
                        Text("\(count)")
                            .font(.system(size: counterFontSize, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255)) // onBackground

                        Spacer()

                        // Increment pill button
                        Button(action: {
                            onIncrement()
                            onAddToCartAnimation?(product.imageUrl, imagePosition)
                        }) {
                            Text("+")
                                .font(.system(size: counterFontSize, weight: .bold, design: .default))
                                .foregroundColor(Color(red: 19/255, green: 45/255, blue: 47/255)) // onSurfaceVariant
                                .frame(width: buttonSize, height: buttonSize)
                                .background(Color(red: 243/255, green: 243/255, blue: 243/255)) // background
                                .clipShape(Circle())
                        }
                    }
                    .frame(height: 26 * scaleFactor)
                    .offset(y: 7 * scaleFactor)
                    .padding(.horizontal, 12 * scaleFactor)
                    .padding(.bottom, 12 * scaleFactor)
                    .background(
                        CounterControlsShape()
                            .fill(Color(red: 225/255, green: 199/255, blue: 142/255)) // secondary
                    )
                }
            }
            .padding(.horizontal, 4 * scaleFactor)
            .padding(.bottom, 4 * scaleFactor)


            }
            .onPreferenceChange(ImagePositionKey.self) { position in
                imagePosition = position
                print("📍 Product \(product.id) image position updated: \(position)")
            }
        }
        .aspectRatio(155.0/290.0, contentMode: .fit)
        .background(
            CurvedBottomShape()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        
    }
}
