import SwiftUI
import Lottie

public struct LottieView: UIViewRepresentable {
    public enum Source {
        case name(String)
        case url(URL)
    }

    private let source: Source
    private let loopMode: LottieLoopMode
    private let contentMode: UIView.ContentMode
    private let speed: CGFloat

    public init(name: String, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
        self.source = .name(name)
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.speed = speed
    }

    public init(url: URL, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
        self.source = .url(url)
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.speed = speed
    }

    public func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let animationView = LottieAnimationView()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed
        animationView.backgroundBehavior = .pauseAndRestore

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        context.coordinator.animationView = animationView
        loadAnimation(into: animationView)
        return container
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // No-op. If needed, we could control play/pause based on external state.
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        var animationView: LottieAnimationView?
    }

    private func loadAnimation(into animationView: LottieAnimationView) {
        switch source {
        case .name(let name):
            animationView.animation = LottieAnimation.named(name)
            animationView.play()
        case .url(let url):
            // Load from remote URL (Lottie 4+ API)
            LottieAnimation.loadedFrom(url: url, closure: { animation in
                DispatchQueue.main.async {
                    animationView.animation = animation
                    animationView.play()
                }
            }, animationCache: LRUAnimationCache.sharedCache)
        }
    }
}
