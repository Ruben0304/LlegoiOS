import SwiftUI
import AVKit

struct TutorialsView: View {
    @StateObject private var viewModel = TutorialsViewModel()
    @Environment(\.dismiss) private var dismiss

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.tutorials) { tutorial in
                                    TutorialCard(tutorial: tutorial) {
                                        viewModel.selectTutorial(tutorial)
                                    }
                                    .frame(height: 200)
                                }
                            }
                            .padding(.horizontal, 16)
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

    var body: some View {
        Button(action: onTap) {
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
                .position(x: UIScreen.main.bounds.width / 2 - 16, y: 100)

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
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
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

// MARK: - Video Player View
struct VideoPlayerView: View {
    let tutorial: Tutorial
    let onDismiss: () -> Void

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(20)
                }
                Spacer()
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
            if let url = URL(string: tutorial.videoUrl) {
                player = AVPlayer(url: url)
                player?.play()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

#Preview {
    TutorialsView()
}
