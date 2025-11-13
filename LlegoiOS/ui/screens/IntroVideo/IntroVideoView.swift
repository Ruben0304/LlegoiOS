import SwiftUI
import AVKit
import AVFoundation

struct IntroVideoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var navigateToChat = false

    var body: some View {
        NavigationStack {
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
                        navigateToChat = true
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $navigateToChat) {
                ConversationalSearchView()
            }
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
            }
        }
    }

    // MARK: - Setup Player
    private func setupPlayer() {
        // Obtener la ruta del video desde el bundle
        guard let videoURL = Bundle.main.url(forResource: "intro_video", withExtension: "mp4") else {
            print("⚠️ No se encontró el video 'intro_video.mp4' en el bundle")
            // Si no se encuentra el video, ir directamente al chat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                navigateToChat = true
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
            // Navegar al chat cuando termine el video
            navigateToChat = true
        }

        // Iniciar reproducción automática
        player?.play()
    }

    // MARK: - Cleanup Player
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
}

#Preview {
    IntroVideoView()
}
