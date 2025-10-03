import SwiftUI

struct AddToCartAnimation: View {
    let imageUrl: String
    let startPosition: CGPoint
    let endPosition: CGPoint
    let onAnimationEnd: () -> Void

    @State private var currentPosition: CGPoint
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    init(imageUrl: String, startPosition: CGPoint, endPosition: CGPoint, onAnimationEnd: @escaping () -> Void) {
        self.imageUrl = imageUrl
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.onAnimationEnd = onAnimationEnd
        _currentPosition = State(initialValue: startPosition)
    }

    var body: some View {
        AsyncImage(url: URL(string: imageUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Circle()
                .fill(Color.white)
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
        .background(
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 8)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .position(currentPosition)  // Usar position directamente
        .onAppear {
            print("🎬 AddToCartAnimation:")
            print("  Start: \(startPosition)")
            print("  End: \(endPosition)")

            // Animar hacia la posición final
            withAnimation(.easeInOut(duration: 0.6)) {
                currentPosition = endPosition
                scale = 0.5
                opacity = 0.7
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onAnimationEnd()
            }
        }
    }
}