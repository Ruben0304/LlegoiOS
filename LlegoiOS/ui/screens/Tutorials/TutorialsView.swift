import SwiftUI
import AVKit

struct TutorialsView: View {
    @StateObject private var viewModel = TutorialsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.llegoBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Navigation Bar

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Aprende a usar Llego")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.llegoPrimary)

                            Text("Descubre todos los tips y trucos para sacar el máximo provecho de tu experiencia de compra.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                        if viewModel.isLoading && viewModel.tutorials.isEmpty {
                            ProgressView("Cargando tutoriales...")
                                .padding(.top, 32)
                        } else if let errorMessage = viewModel.errorMessage, viewModel.tutorials.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                        } else {
                            // Featured tutorial (first one)
                            if let featured = viewModel.tutorials.first {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Destacado")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.llegoTertiary)
                                        .padding(.horizontal, 16)

                                    FeaturedTutorialCard(tutorial: featured) {
                                        viewModel.selectTutorial(featured)
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }

                            // All tutorials grid
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Todos los tutoriales")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.llegoPrimary)
                                    .padding(.horizontal, 16)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                    ForEach(viewModel.tutorials) { tutorial in
                                            TutorialCard(
                                                tutorial: tutorial,
                                                cardWidth: 272,
                                                cardHeight: 156,
                                                accentColor: .llegoPrimary
                                            ) {
                                            viewModel.selectTutorial(tutorial)
                                        }
                                    }
                                }
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $viewModel.selectedTutorial) { tutorial in
            VideoPlayerView(tutorial: tutorial, onDismiss: {
                viewModel.closeTutorial()
            })
        }
        .navigationTitle("Tutoriales")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton(action: {
                    dismiss()
                })
            }
        }
    }
}

// MARK: - Featured Tutorial Card
struct FeaturedTutorialCard: View {
    let tutorial: Tutorial
    let onTap: () -> Void

    @State private var isPressed: Bool = false
    @ObservedObject private var downloadManager = TutorialDownloadManager.shared

    var body: some View {
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
            .frame(height: 200)
            .clipped()
            .cornerRadius(16)

            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.7),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .center
            )
            .cornerRadius(16)

            // Play button
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 60, height: 60)

                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.llegoPrimary)
                    .offset(x: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            // Info overlay
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let category = tutorial.category {
                        Text(category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.9))
                            )
                    }

                    Spacer()

                    Text(tutorial.duration)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.7))
                        )
                }

                Text(tutorial.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(height: 200)
        .overlay(alignment: .topLeading) {
            downloadBadge
                .padding(12)
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    @ViewBuilder
    private var downloadBadge: some View {
        switch downloadManager.status(for: tutorial.id) {
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.green)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        case .downloading(let progress):
            HStack(spacing: 6) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(width: 18, height: 18)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.65), in: Capsule())
        case .failed:
            Button(action: { downloadManager.startDownload(for: tutorial) }) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        case .notDownloaded:
            Button(action: { downloadManager.startDownload(for: tutorial) }) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let tutorial: Tutorial
    let onDismiss: () -> Void

    @State private var player: AVPlayer?
    @State private var playbackError: String?
    @ObservedObject private var downloadManager = TutorialDownloadManager.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            // Top controls
            VStack {
                HStack {
                    downloadControl
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }

            if let playbackError {
                Text(playbackError)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }

            // Tutorial info overlay
            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: 8) {
                    Text(tutorial.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(tutorial.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)

                    if let category = tutorial.category {
                        Text(category)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.llegoSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.9))
                            )
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.7),
                            Color.clear
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
        }
        .onAppear {
            startPlayback()
        }
        .onChange(of: downloadManager.status(for: tutorial.id)) { _ in
            swapToDownloadedFileIfNeeded()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @ViewBuilder
    private var downloadControl: some View {
        switch downloadManager.status(for: tutorial.id) {
        case .downloaded:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                Text("Descargado")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())

        case .downloading(let progress):
            HStack(spacing: 8) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .frame(width: 18, height: 18)
                Text("Descargando \(Int(progress * 100))%")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.6), in: Capsule())

        case .failed:
            Button(action: { downloadManager.startDownload(for: tutorial) }) {
                Label("Reintentar", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.8), in: Capsule())
            }
            .buttonStyle(.plain)

        case .notDownloaded:
            Button(action: { downloadManager.startDownload(for: tutorial) }) {
                Label("Descargar", systemImage: "arrow.down.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private func startPlayback() {
        guard let url = downloadManager.playbackURL(for: tutorial) else {
            playbackError = "No se pudo cargar este video"
            return
        }

        playbackError = nil
        player = AVPlayer(url: url)
        player?.play()
    }

    private func swapToDownloadedFileIfNeeded() {
        guard case .downloaded(let localURL) = downloadManager.status(for: tutorial.id) else { return }
        guard let currentURL = (player?.currentItem?.asset as? AVURLAsset)?.url else { return }
        guard currentURL != localURL else { return }

        let currentTime = player?.currentTime() ?? .zero
        let wasPlaying = (player?.rate ?? 0) > 0

        player?.pause()
        player = AVPlayer(url: localURL)
        player?.seek(to: currentTime)
        if wasPlaying {
            player?.play()
        }
    }
}

#Preview {
    TutorialsView()
}
