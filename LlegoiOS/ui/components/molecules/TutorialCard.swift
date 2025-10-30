import SwiftUI
import AVKit

struct TutorialCard: View {
    let tutorial: Tutorial
    var onTutorialTap: (() -> Void)? = nil

    @State private var isPressed: Bool = false

    var body: some View {
        GeometryReader { containerGeometry in
            let cardWidth = containerGeometry.size.width
            let scaleFactor = cardWidth / 200.0
            let imageSize = 180 * scaleFactor
            let nameFontSize = 15 * scaleFactor
            let durationFontSize = 12 * scaleFactor
            let nameHeight = 40 * scaleFactor
            let horizontalPadding = 10 * scaleFactor
            let topPadding = 10 * scaleFactor
            let spacingAfterImage = 8 * scaleFactor
            let playButtonSize = 50 * scaleFactor

            VStack(alignment: .center, spacing: 0) {
                // Main content
                VStack(alignment: .center, spacing: 0) {
                    // Thumbnail image with play button overlay
                    ZStack {
                        CachedAsyncImage(
                            url: URL(string: tutorial.thumbnailUrl),
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            },
                            placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                        )
                        .frame(width: imageSize, height: imageSize * 0.65)
                        .clipped()
                        .cornerRadius(12 * scaleFactor)

                        // Play button overlay
                        ZStack {
                            Circle()
                                .glassEffect(.regular.interactive())
                                .frame(width: playButtonSize, height: playButtonSize)

                            Image(systemName: "play.fill")
                                .font(.system(size: playButtonSize * 0.4, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: playButtonSize * 0.05)
                        }

                        // Duration badge
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Text(tutorial.duration)
                                    .font(.system(size: durationFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8 * scaleFactor)
                                    .padding(.vertical, 4 * scaleFactor)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6 * scaleFactor)
                                            .fill(Color.black.opacity(0.7))
                                    )
                                    .padding([.trailing, .bottom], 8 * scaleFactor)
                            }
                        }
                    }
                    .frame(width: imageSize, height: imageSize * 0.65)

                    Spacer().frame(height: spacingAfterImage)

                    // Tutorial title with fixed height for 2 lines
                    VStack {
                        Text(tutorial.title)
                            .font(.system(size: nameFontSize, weight: .bold, design: .default))
                            .foregroundColor(Color(red: 97/255, green: 97/255, blue: 97/255))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: nameHeight, alignment: .center)
                            .frame(maxWidth: .infinity)
                    }

                    // Category (if available)
                    if let category = tutorial.category {
                        Text(category)
                            .font(.system(size: durationFontSize, weight: .regular, design: .default))
                            .foregroundColor(Color.llegoTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)

                Spacer()
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .aspectRatio(200.0/220.0, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.llegoPrimary.opacity(isPressed ? 0.6 : 0), lineWidth: 3)
                .animation(.easeInOut(duration: 0.15), value: isPressed)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTutorialTap?()
        }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
