import SwiftUI
import UIKit

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

struct AdWatcherView: View {
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentAdIndex: Int = 0
    @State private var secondsRemaining: Int = 30
    @State private var canSkip: Bool = true  // TODO: Cambiar a false para producción
    @State private var isVideoPlaying: Bool = true
    @State private var showCompletionAnimation: Bool = false
    @State private var timer: Timer?

    private let totalAds = 2
    private let skipAfterSeconds = 30

    // Simulated ad data
    private let ads: [(title: String, brand: String, color: Color, icon: String)] = [
        ("Descubre ofertas increíbles", "MegaStore", .blue, "bag.fill"),
        ("Tu próximo viaje te espera", "TravelMax", .purple, "airplane"),
    ]

    var body: some View {
        ZStack {
            // Background gradient based on current ad
            LinearGradient(
                colors: [
                    ads[currentAdIndex].color.opacity(0.8),
                    ads[currentAdIndex].color.opacity(0.4),
                    Color.black.opacity(0.9),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with progress and timer
                adTopBar

                Spacer()

                // Simulated video content
                simulatedVideoContent

                Spacer()

                // Bottom controls
                adBottomControls
            }

            // Completion animation overlay
            if showCompletionAnimation {
                completionOverlay
            }
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    // MARK: - Top Bar
    private var adTopBar: some View {
        VStack(spacing: 12) {
            // Progress indicators
            HStack(spacing: 6) {
                ForEach(0..<totalAds, id: \.self) { index in
                    Capsule()
                        .fill(
                            index < currentAdIndex
                                ? Color.white
                                : (index == currentAdIndex
                                    ? Color.white.opacity(0.9) : Color.white.opacity(0.3))
                        )
                        .frame(height: 3)
                        .overlay(
                            GeometryReader { geo in
                                if index == currentAdIndex {
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(
                                            width: geo.size.width
                                                * CGFloat(skipAfterSeconds - secondsRemaining)
                                                / CGFloat(skipAfterSeconds))
                                }
                            }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Ad info and timer
            HStack {
                // Ad counter
                HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Anuncio \(currentAdIndex + 1) de \(totalAds)")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Timer badge
                HStack(spacing: 4) {
                    Image(systemName: canSkip ? "forward.fill" : "clock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(canSkip ? "Omitir" : "\(secondsRemaining)s")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(canSkip ? Color.green : Color.white.opacity(0.2))
                )
                .onTapGesture {
                    if canSkip {
                        skipOrFinishAd()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 50)
    }

    // MARK: - Simulated Video Content
    private var simulatedVideoContent: some View {
        VStack(spacing: 24) {
            // Brand icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: ads[currentAdIndex].icon)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isVideoPlaying ? 1.0 : 0.95)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isVideoPlaying)

            // Ad text
            VStack(spacing: 12) {
                Text(ads[currentAdIndex].brand)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(2)

                Text(ads[currentAdIndex].title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Simulated video progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)

                        Capsule()
                            .fill(Color.white)
                            .frame(
                                width: geo.size.width * CGFloat(skipAfterSeconds - secondsRemaining)
                                    / CGFloat(skipAfterSeconds), height: 4)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 40)

                // Video duration indicator
                HStack {
                    Text(formatTime(skipAfterSeconds - secondsRemaining))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                    Spacer()
                    Text(formatTime(skipAfterSeconds))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Bottom Controls
    private var adBottomControls: some View {
        VStack(spacing: 16) {
            // Info about discount
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 14, weight: .semibold))

                Text("Mira \(totalAds) videos y reduce tu cargo de servicio al 10%")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )

            // Sound toggle (simulated)
            HStack(spacing: 20) {
                Button(action: {}) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Button(action: {}) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.bottom, 50)
    }

    // MARK: - Completion Overlay
    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(spacing: 8) {
                    Text("¡Descuento activado!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Tu cargo de servicio ahora es del 10%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Button(action: {
                    onComplete()
                }) {
                    Text("Continuar")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .modifier(GlassProminentButtonModifier())
                .tint(.green)
                .padding(.horizontal, 40)
                .padding(.top, 16)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Timer Logic
    private func startTimer() {
        secondsRemaining = skipAfterSeconds
        canSkip = false

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                if secondsRemaining > 0 {
                    secondsRemaining -= 1
                    if secondsRemaining == 0 {
                        canSkip = true
                    }
                }
            }
        }
    }

    private func skipOrFinishAd() {
        timer?.invalidate()

        if currentAdIndex < totalAds - 1 {
            // Move to next ad
            withAnimation(.easeInOut(duration: 0.3)) {
                currentAdIndex += 1
            }
            startTimer()
        } else {
            // All ads watched - show completion
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showCompletionAnimation = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
