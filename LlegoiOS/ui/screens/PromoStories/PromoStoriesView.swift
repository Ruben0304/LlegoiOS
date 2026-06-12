import SwiftUI
import AVFoundation
import Combine

// MARK: - Player Engine

@MainActor
final class PromoPlayerEngine: ObservableObject {
    @Published private(set) var index: Int = 0
    @Published private(set) var progress: Double = 0

    let player = AVPlayer()
    private(set) var videos: [PromotionalVideo] = []
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?

    var onFinishedAll: (() -> Void)?

    var current: PromotionalVideo? {
        videos.indices.contains(index) ? videos[index] : nil
    }

    func configure(videos: [PromotionalVideo]) {
        guard !videos.isEmpty else { return }
        self.videos = videos
        player.isMuted = false
        setupObservers()
        playItem(at: 0)
    }

    func next() {
        if index < videos.count - 1 {
            playItem(at: index + 1)
        } else {
            finish()
        }
    }

    func previous() {
        if index > 0 {
            playItem(at: index - 1)
        } else {
            // Restart current
            player.seek(to: .zero)
            progress = 0
            player.play()
        }
    }

    func pause() { player.pause() }
    func resume() { player.play() }

    func teardown() {
        if let timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player.pause()
        player.replaceCurrentItem(with: nil)
    }

    // MARK: - Private

    private func setupObservers() {
        let interval = CMTime(seconds: 0.05, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval, queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                guard let self, let item = self.player.currentItem else { return }
                let itemDuration = item.duration.seconds
                let fallback = Double(self.current?.duration ?? 0)
                let total = (itemDuration.isFinite && itemDuration > 0) ? itemDuration : fallback
                guard total > 0 else { return }
                self.progress = min(max(time.seconds / total, 0), 1)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
    }

    private func playItem(at i: Int) {
        guard videos.indices.contains(i) else { return }
        index = i
        progress = 0

        guard let url = URL(string: videos[i].videoUrl) else {
            next()
            return
        }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.seek(to: .zero)
        player.play()
    }

    private func finish() {
        player.pause()
        onFinishedAll?()
    }
}

// MARK: - AVPlayerLayer host (aspect fill, no default controls)

private struct PromoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        PlayerUIView(player: player)
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        init(player: AVPlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspectFill
            backgroundColor = .black
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - Stories View

struct PromoStoriesView: View {
    /// Called when the user finishes watching all promos (grants the discount).
    let onComplete: () -> Void
    /// Called when the user dismisses without finishing.
    let onClose: () -> Void

    @StateObject private var viewModel = PromoStoriesViewModel()
    @StateObject private var engine = PromoPlayerEngine()
    @State private var didConfigure = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else if viewModel.videos.isEmpty {
                emptyState
            } else {
                player
            }
        }
        .onAppear {
            engine.onFinishedAll = { onComplete() }
            viewModel.load()
        }
        .onDisappear { engine.teardown() }
        .onChange(of: viewModel.videos) { newVideos in
            guard !didConfigure, !newVideos.isEmpty else { return }
            didConfigure = true
            engine.configure(videos: newVideos)
        }
    }

    // MARK: - Player

    private var player: some View {
        ZStack(alignment: .top) {
            PromoPlayerLayerView(player: engine.player)
                .ignoresSafeArea()

            // Tap zones: left third -> previous, right two thirds -> next
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(width: geo.size.width * 0.3)
                        .onTapGesture { engine.previous() }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { engine.next() }
                }
            }
            .ignoresSafeArea()

            // Dim gradient for readability of overlays
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 160)
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 180)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                progressBars
                header
                Spacer()
                caption
            }
            .padding(.top, 8)
        }
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 120 {
                        onClose()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(engine.videos.indices, id: \.self) { i in
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * fillFraction(for: i))
                        }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 12)
    }

    private func fillFraction(for i: Int) -> Double {
        if i < engine.index { return 1 }
        if i == engine.index { return engine.progress }
        return 0
    }

    private var header: some View {
        HStack(spacing: 10) {
            if let avatar = engine.current?.branchAvatarUrl, let url = URL(string: avatar) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.2))
                }
                .frame(width: 34, height: 34)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            }

            if let name = engine.current?.branchName, !name.isEmpty {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(8)
            }
        }
        .padding(.horizontal, 14)
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let title = engine.current?.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            if let description = engine.current?.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
    }

    // MARK: - Empty / error state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.white.opacity(0.7))
            Text(viewModel.errorMessage ?? "No hay promociones disponibles por ahora")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onClose) {
                Text("Cerrar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white))
            }
        }
    }
}
