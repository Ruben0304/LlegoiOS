//import SwiftUI
//import Lottie
//
//public struct LottieView: UIViewRepresentable {
//    public enum Source {
//        case name(String)
//        case url(URL)
//        case dotLottieName(String)  // Para archivos .lottie locales
//        case dotLottieURL(URL)      // Para archivos .lottie remotos
//    }
//
//    private let source: Source
//    private let loopMode: LottieLoopMode
//    private let contentMode: UIView.ContentMode
//    private let speed: CGFloat
//
//    public init(name: String, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
//        self.source = .name(name)
//        self.loopMode = loopMode
//        self.contentMode = contentMode
//        self.speed = speed
//    }
//    
//    public init(name: String) {
//        // Detectar automáticamente si es .lottie o .json
//        if Bundle.main.url(forResource: name, withExtension: "lottie") != nil {
//            self.source = .dotLottieName(name)
//        } else {
//            self.source = .name(name)
//        }
//        self.loopMode = .loop
//        self.contentMode = .scaleAspectFit
//        self.speed = 1.0
//    }
//
//    public init(url: URL, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
//        // Detectar si es .lottie basado en la extensión
//        if url.pathExtension.lowercased() == "lottie" {
//            self.source = .dotLottieURL(url)
//        } else {
//            self.source = .url(url)
//        }
//        self.loopMode = loopMode
//        self.contentMode = contentMode
//        self.speed = speed
//    }
//    
//    // Inicializadores específicos para .lottie
//    public init(dotLottieName: String, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
//        self.source = .dotLottieName(dotLottieName)
//        self.loopMode = loopMode
//        self.contentMode = contentMode
//        self.speed = speed
//    }
//    
//    public init(dotLottieURL: URL, loopMode: LottieLoopMode = .loop, contentMode: UIView.ContentMode = .scaleAspectFit, speed: CGFloat = 1.0) {
//        self.source = .dotLottieURL(dotLottieURL)
//        self.loopMode = loopMode
//        self.contentMode = contentMode
//        self.speed = speed
//    }
//
//    public func makeUIView(context: Context) -> UIView {
//        let container = UIView()
//        container.backgroundColor = .clear
//
//        let animationView = LottieAnimationView()
//        animationView.translatesAutoresizingMaskIntoConstraints = false
//        animationView.contentMode = contentMode
//        animationView.loopMode = loopMode
//        animationView.animationSpeed = speed
//        animationView.backgroundBehavior = .pauseAndRestore
//
//        container.addSubview(animationView)
//        NSLayoutConstraint.activate([
//            animationView.topAnchor.constraint(equalTo: container.topAnchor),
//            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
//            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
//            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
//        ])
//
//        context.coordinator.animationView = animationView
//        loadAnimation(into: animationView)
//        return container
//    }
//
//    public func updateUIView(_ uiView: UIView, context: Context) {
//        // No-op. If needed, we could control play/pause based on external state.
//    }
//
//    public func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    public class Coordinator {
//        var animationView: LottieAnimationView?
//    }
//
//    private func loadAnimation(into animationView: LottieAnimationView) {
//        switch source {
//        case .name(let name):
//            // Archivo JSON tradicional
//            animationView.animation = LottieAnimation.named(name)
//            animationView.play()
//            
//        case .url(let url):
//            // JSON desde URL remota
//            LottieAnimation.loadedFrom(url: url, closure: { animation in
//                DispatchQueue.main.async {
//                    animationView.animation = animation
//                    animationView.play()
//                }
//            }, animationCache: LRUAnimationCache.sharedCache)
//            
//        case .dotLottieName(let name):
//            // Archivo .lottie local
//            guard let url = Bundle.main.url(forResource: name, withExtension: "lottie") else {
//                print("Error: No se pudo encontrar el archivo \(name).lottie en el bundle")
//                return
//            }
//            
//            DotLottieFile.loadedFrom(url: url) { result in
//                DispatchQueue.main.async {
//                    switch result {
//                    case .success(let dotLottie):
//                        animationView.loadAnimation(from: dotLottie)
//                        animationView.play()
//                    case .failure(let error):
//                        print("Error cargando archivo .lottie: \(error)")
//                    }
//                }
//            }
//            
//        case .dotLottieURL(let url):
//            // Archivo .lottie desde URL remota
//            DotLottieFile.loadedFrom(url: url) { result in
//                DispatchQueue.main.async {
//                    switch result {
//                    case .success(let dotLottie):
//                        animationView.loadAnimation(from: dotLottie)
//                        animationView.play()
//                    case .failure(let error):
//                        print("Error cargando archivo .lottie remoto: \(error)")
//                    }
//                }
//            }
//        }
//    }
//}
