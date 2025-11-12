import SwiftUI

/// Vista a pantalla completa para ver historias estilo Instagram
struct InstagramStoryViewer: View {
    @Binding var stories: [StoryData]
    @Binding var currentStoryIndex: Int
    @Binding var isPresented: Bool

    @State private var currentItemProgress: Double = 0
    @State private var timer: Timer?
    @State private var dragOffset: CGFloat = 0
    @State private var isPaused: Bool = false
    @State private var messageText: String = ""
    @State private var isMuted: Bool = false
    @FocusState private var isMessageFieldFocused: Bool

    private let quickReactions: [String] = ["❤️", "😂", "🔥", "👏", "😮", "😢"]

    private var currentStory: StoryData {
        stories[currentStoryIndex]
    }

    private var currentItem: StoryItem {
        currentStory.items[currentStory.currentIndex]
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            storyMediaView
            topGradientOverlay
            bottomGradientOverlay

            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    progressBars
                    storyHeader
                }
                .padding(.horizontal, 12)
                .padding(.top, 48)

                Spacer()

                bottomMessageComposer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }

            navigationGestures
        }
        .statusBar(hidden: true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: isMessageFieldFocused) { isFocused in
            if isFocused {
                pauseTimer()
            } else {
                resumeTimer()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                    if dragOffset > 0 {
                        pauseTimer()
                    }
                }
                .onEnded { value in
                    if value.translation.height > 150 {
                        closeViewer()
                    } else {
                        dragOffset = 0
                        resumeTimer()
                    }
                }
        )
        .offset(y: dragOffset)
    }

    // MARK: - Gradients
    private var topGradientOverlay: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.85),
                Color.black.opacity(0.4),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .center
        )
        .ignoresSafeArea(edges: .top)
    }

    private var bottomGradientOverlay: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.35),
                Color.black.opacity(0.9)
            ],
            startPoint: .center,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Story Media View
    private var storyMediaView: some View {
        AsyncImage(url: URL(string: currentItem.mediaUrl)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            case .failure:
                Color.gray
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                    )
            @unknown default:
                EmptyView()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Progress Bars
    private var progressBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<currentStory.items.count, id: \.self) { index in
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.35))

                        Capsule()
                            .fill(Color.white)
                            .frame(width: progressWidth(for: index, totalWidth: geometry.size.width))
                    }
                }
                .frame(height: 2)
            }
        }
    }

    private func progressWidth(for index: Int, totalWidth: CGFloat) -> CGFloat {
        if index < currentStory.currentIndex {
            return totalWidth
        } else if index == currentStory.currentIndex {
            return totalWidth * currentItemProgress
        } else {
            return 0
        }
    }

    // MARK: - Story Header
    private var storyHeader: some View {
        HStack(spacing: 12) {
            storyProfileImage

            VStack(alignment: .leading, spacing: 2) {
                Text(currentStory.store.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(timeAgo(from: currentItem.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: toggleMute) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }

                Button(action: handleMoreOptions) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }

                Button(action: closeViewer) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var storyProfileImage: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.99, green: 0.55, blue: 0.23),
                            Color(red: 0.91, green: 0.11, blue: 0.39),
                            Color(red: 0.56, green: 0.18, blue: 0.99),
                            Color(red: 0.99, green: 0.55, blue: 0.23)
                        ]),
                        center: .center
                    )
                )
                .frame(width: 44, height: 44)

            AsyncImage(url: URL(string: currentStory.store.logoUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty, .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "storefront")
                                .foregroundColor(.white)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Navigation Gestures
    private var navigationGestures: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    previousItem()
                }

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    nextItem()
                }
        }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            if pressing {
                pauseTimer()
            } else {
                resumeTimer()
            }
        }, perform: {})
    }

    // MARK: - Bottom Composer
    private var bottomMessageComposer: some View {
        VStack(alignment: .leading, spacing: 14) {
            quickReactionRow

            HStack(spacing: 12) {
                Button(action: openCameraComposer) {
                    Image(systemName: "camera")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }

                HStack(spacing: 8) {
                    TextField("Enviar mensaje", text: $messageText)
                        .focused($isMessageFieldFocused)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(true)
                        .submitLabel(.send)
                        .onSubmit {
                            handleSendMessage()
                        }

                    Button(action: handleSendMessage) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .rotationEffect(.degrees(13))
                            .foregroundColor(
                                .white.opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                            )
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    private var quickReactionRow: some View {
        HStack(spacing: 12) {
            ForEach(quickReactions, id: \.self) { emoji in
                Button {
                    handleQuickReaction(emoji)
                } label: {
                    Text(emoji)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Spacer()
        }
    }

    // MARK: - Timer Management
    private func startTimer() {
        currentItemProgress = 0
        let totalSteps = 100.0
        let stepDuration = currentItem.duration / totalSteps

        timer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { _ in
            if !isPaused {
                currentItemProgress += 1.0 / totalSteps

                if currentItemProgress >= 1.0 {
                    nextItem()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func pauseTimer() {
        isPaused = true
    }

    private func resumeTimer() {
        isPaused = false
    }

    // MARK: - Navigation Methods
    private func nextItem() {
        if stories[currentStoryIndex].currentIndex < stories[currentStoryIndex].items.count - 1 {
            stories[currentStoryIndex].currentIndex += 1
            stopTimer()
            startTimer()
        } else {
            nextStory()
        }
    }

    private func previousItem() {
        if currentItemProgress < 0.1 && stories[currentStoryIndex].currentIndex > 0 {
            stories[currentStoryIndex].currentIndex -= 1
            stopTimer()
            startTimer()
        } else if currentItemProgress < 0.1 {
            previousStory()
        } else {
            stopTimer()
            startTimer()
        }
    }

    private func nextStory() {
        if currentStoryIndex < stories.count - 1 {
            stories[currentStoryIndex].isViewed = true
            stories[currentStoryIndex].currentIndex = 0

            currentStoryIndex += 1
            stopTimer()
            startTimer()
        } else {
            closeViewer()
        }
    }

    private func previousStory() {
        if currentStoryIndex > 0 {
            stories[currentStoryIndex].currentIndex = 0
            currentStoryIndex -= 1
            stories[currentStoryIndex].currentIndex = stories[currentStoryIndex].items.count - 1
            stopTimer()
            startTimer()
        }
    }

    private func closeViewer() {
        stopTimer()
        isMessageFieldFocused = false
        withAnimation(.easeOut(duration: 0.3)) {
            isPresented = false
        }
    }

    private func toggleMute() {
        isMuted.toggle()
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func handleMoreOptions() {
        pauseTimer()
        print("Mostrar opciones para \(currentStory.store.name)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            resumeTimer()
        }
    }

    private func handleLike() {
        stories[currentStoryIndex].isLiked.toggle()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func handleQuickReaction(_ emoji: String) {
        pauseTimer()
        if emoji == "❤️" {
            handleLike()
        } else {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }

        print("Reacción \(emoji) para \(currentStory.store.name)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            resumeTimer()
        }
    }

    private func handleSendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        pauseTimer()
        print("Enviar mensaje \"\(trimmed)\" a \(currentStory.store.name)")
        messageText = ""

        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isMessageFieldFocused = false
            resumeTimer()
        }
    }

    private func openCameraComposer() {
        pauseTimer()
        print("Abrir cámara para historia de \(currentStory.store.name)")
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            resumeTimer()
        }
    }

    // MARK: - Helper Methods
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        let minutes = Int(seconds / 60)
        let hours = Int(seconds / 3600)

        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Ahora"
        }
    }
}

// MARK: - Preview
struct InstagramStoryViewer_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStore = Store(
            id: "1",
            name: "FreshMart Premium",
            etaMinutes: 25,
            logoUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=200&h=200&fit=crop&crop=center",
            bannerUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&h=200&fit=crop&crop=center",
            address: "Calle 23, Vedado"
        )

        let storyItems = [
            StoryItem(
                mediaUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=1080&h=1920&fit=crop",
                mediaType: .image,
                duration: 5.0,
                timestamp: Date().addingTimeInterval(-3600)
            ),
            StoryItem(
                mediaUrl: "https://images.unsplash.com/photo-1488459716781-31db52582fe9?w=1080&h=1920&fit=crop",
                mediaType: .image,
                duration: 5.0,
                timestamp: Date().addingTimeInterval(-1800)
            )
        ]

        @State var stories = [StoryData(id: "1", store: sampleStore, items: storyItems)]
        @State var currentIndex = 0
        @State var isPresented = true

        return InstagramStoryViewer(
            stories: $stories,
            currentStoryIndex: $currentIndex,
            isPresented: $isPresented
        )
    }
}
