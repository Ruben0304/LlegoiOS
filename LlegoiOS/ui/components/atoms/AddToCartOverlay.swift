import SwiftUI

struct AddToCartOverlayModifier: ViewModifier {
    @Binding var animationTrigger: AnimationData?
    let onAnimationEnd: () -> Void

    @State private var currentAnimation: AnimationData?
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        ZStack {
            content

            // Overlay absoluto para la animación
            if let animation = currentAnimation, isAnimating {
                GeometryReader { geometry in
                    AddToCartAnimation(
                        imageUrl: animation.imageUrl,
                        startPosition: animation.startPosition,
                        endPosition: animation.endPosition,
                        onAnimationEnd: {
                            isAnimating = false
                            currentAnimation = nil
                            onAnimationEnd()
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                }
                .allowsHitTesting(false)
                .zIndex(1000)
            }
        }
        .onChange(of: animationTrigger) { _, newValue in
            if let newAnimation = newValue {
                currentAnimation = newAnimation
                isAnimating = true
                // Limpiar el trigger después de procesarlo
                DispatchQueue.main.async {
                    animationTrigger = nil
                }
            }
        }
    }
}

extension View {
    func addToCartOverlay(animationTrigger: Binding<AnimationData?>, onAnimationEnd: @escaping () -> Void) -> some View {
        self.modifier(AddToCartOverlayModifier(animationTrigger: animationTrigger, onAnimationEnd: onAnimationEnd))
    }
}