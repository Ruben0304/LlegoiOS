import SwiftUI

struct TutorialSection: View {
    let tutorials: [Tutorial]
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let onSeeMoreClick: () -> Void
    var onTutorialTap: ((Tutorial) -> Void)? = nil
    var title: String = "Tutoriales"
    var actionTitle: String = "Ver más"
    var accentColor: Color = Color(red: 124/255, green: 65/255, blue: 43/255)
    @State private var animationDelay: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))

                Spacer()

                Button(action: onSeeMoreClick) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .semibold, design: .default))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Tutorials horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(tutorials.enumerated()), id: \.element.id) { index, tutorial in
                        TutorialCard(
                            tutorial: tutorial,
                            onTutorialTap: {
                                onTutorialTap?(tutorial)
                            }
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .opacity(animationDelay > Double(index) * 0.1 ? 1 : 0)
                        .scaleEffect(animationDelay > Double(index) * 0.1 ? 1 : 0.95)
                        .offset(y: animationDelay > Double(index) * 0.1 ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.8)
                                .delay(Double(index) * 0.05),
                            value: animationDelay
                        )
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    triggerAnimation(for: tutorials.count)
                }
                .onChange(of: tutorials.map(\.id)) { _ in
                    triggerAnimation(for: tutorials.count)
                }
            }
        }
    }

    private func triggerAnimation(for count: Int) {
        animationDelay = 0
        guard count > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animationDelay = Double(count) * 0.1 + 0.1
        }
    }
}
