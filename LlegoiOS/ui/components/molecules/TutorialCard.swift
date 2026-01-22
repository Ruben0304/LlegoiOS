import SwiftUI
import AVKit

struct TutorialCard: View {
    let tutorial: Tutorial
    var onTutorialTap: (() -> Void)? = nil

    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            onTutorialTap?()
        }) {
            ZStack(alignment: .bottomLeading) {
                // Background image
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                // Gradient overlay - darker for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.75),
                        Color.clear
                    ]),
                    startPoint: .bottom,
                    endPoint: .center
                )

                // Play button - center
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 48, height: 48)

                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.llegoPrimary)
                        .offset(x: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Duration badge - top right
                VStack {
                    HStack {
                        Spacer()
                        Text(tutorial.duration)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.black.opacity(0.7))
                            )
                            .padding([.trailing, .top], 10)
                    }
                    Spacer()
                }

                // Info overlay - bottom with text
                VStack(alignment: .leading, spacing: 4) {
                    if let category = tutorial.category {
                        Text(category)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.9))
                            )
                    }

                    Text(tutorial.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
            }
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}
