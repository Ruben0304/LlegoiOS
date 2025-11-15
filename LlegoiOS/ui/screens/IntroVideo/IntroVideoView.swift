import SwiftUI
import AVKit
import AVFoundation

enum IntroVideoType {
    case intro
    case paymentMethod
    case thanks
}

struct IntroVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var navigateToNext = false
    
    let videoType: IntroVideoType
    let onVideoComplete: () -> Void
    
    init(videoType: IntroVideoType = .intro, onVideoComplete: @escaping () -> Void = {}) {
        self.videoType = videoType
        self.onVideoComplete = onVideoComplete
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Video Player
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .disabled(true) // Deshabilita los controles nativos
            } else {
                // Placeholder mientras se carga el video
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // BackButton a la izquierda
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }

            // Botón "Omitir" a la derecha
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Omitir") {
                    navigateToNext = true
                    onVideoComplete()
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanupPlayer()
        }
        .onChange(of: navigateToNext) { newValue in
            if newValue {
                onVideoComplete()
            }
        }
    }

    // MARK: - Setup Player
    private func setupPlayer() {
        // Determinar qué video reproducir según el tipo
        let videoFileName: String
        let videoExtension: String
        
        switch videoType {
        case .intro:
            videoFileName = "intro_video"
            videoExtension = "mp4"
        case .paymentMethod:
            videoFileName = "metodopago"
            videoExtension = "mp4"
        case .thanks:
            videoFileName = "agradecimiento"
            videoExtension = "mov"
        }
        
        // Obtener la ruta del video desde el bundle
        guard let videoURL = Bundle.main.url(forResource: videoFileName, withExtension: videoExtension) else {
            print("⚠️ No se encontró el video '\(videoFileName).\(videoExtension)' en el bundle")
            // Si no se encuentra el video, continuar con el flujo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToNext = true
                onVideoComplete()
            }
            return
        }

        // Crear el player
        let playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)

        // Configurar el audio para que se reproduzca aunque el dispositivo esté en silencio
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ Error configurando audio session: \(error)")
        }

        // Observer para detectar cuando termina el video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            // Continuar con el flujo cuando termine el video
            navigateToNext = true
            onVideoComplete()
        }

        // Iniciar reproducción automática
        player?.play()
    }

    // MARK: - Cleanup Player
    private func cleanupPlayer() {
        if let playerItem = player?.currentItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        }
        player?.pause()
        player = nil
    }
}

#Preview {
    IntroVideoView(videoType: .intro)
}
