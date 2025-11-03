//
//  StreamingTextView.swift
//  LlegoiOS
//
//  Componente de texto que aparece progresivamente con efecto streaming
//  Inspirado en interfaces conversacionales premium
//

import SwiftUI

/// Segmento de texto que puede ser texto normal o un componente custom
enum TextSegment: Identifiable {
    case text(String)
    case component(id: String, AnyView)

    var id: String {
        switch self {
        case .text(let text):
            return "text_\(text.hashValue)"
        case .component(let id, _):
            return "component_\(id)"
        }
    }
}

/// Vista de texto con efecto streaming (aparición progresiva)
struct StreamingTextView: View {
    let segments: [TextSegment]
    let font: Font
    let color: Color
    let wordDelay: TimeInterval
    let onComplete: (() -> Void)?

    @State private var visibleSegments: Set<String> = []
    @State private var isComplete: Bool = false

    init(
        segments: [TextSegment],
        font: Font = .system(size: 20, weight: .regular),
        color: Color = .onBackgroundColor,
        wordDelay: TimeInterval = 0.08,
        onComplete: (() -> Void)? = nil
    ) {
        self.segments = segments
        self.font = font
        self.color = color
        self.wordDelay = wordDelay
        self.onComplete = onComplete
    }

    /// Inicializador de conveniencia para texto simple
    init(
        text: String,
        font: Font = .system(size: 20, weight: .regular),
        color: Color = .onBackgroundColor,
        wordDelay: TimeInterval = 0.08,
        onComplete: (() -> Void)? = nil
    ) {
        self.segments = [.text(text)]
        self.font = font
        self.color = color
        self.wordDelay = wordDelay
        self.onComplete = onComplete
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                switch segment {
                case .text(let text):
                    // Dividir texto en palabras y mostrarlas progresivamente
                    let words = text.split(separator: " ")
                    ForEach(Array(words.enumerated()), id: \.offset) { wordIndex, word in
                        Text(String(word))
                            .font(font)
                            .foregroundColor(color)
                            .opacity(isWordVisible(segment: segment, wordIndex: wordIndex) ? 1 : 0)
                            .scaleEffect(isWordVisible(segment: segment, wordIndex: wordIndex) ? 1 : 0.95)
                    }

                case .component(let id, let view):
                    view
                        .opacity(visibleSegments.contains(id) ? 1 : 0)
                        .scaleEffect(visibleSegments.contains(id) ? 1 : 0.95)
                }
            }
        }
        .onAppear {
            startStreamingAnimation()
        }
    }

    private func isWordVisible(segment: TextSegment, wordIndex: Int) -> Bool {
        visibleSegments.contains("\(segment.id)_word_\(wordIndex)")
    }

    private func startStreamingAnimation() {
        var currentDelay: TimeInterval = 0
        var allSegmentIds: [String] = []

        for (segmentIndex, segment) in segments.enumerated() {
            switch segment {
            case .text(let text):
                let words = text.split(separator: " ")
                for (wordIndex, _) in words.enumerated() {
                    let wordId = "\(segment.id)_word_\(wordIndex)"
                    allSegmentIds.append(wordId)

                    DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            _ = visibleSegments.insert(wordId)
                        }
                    }
                    currentDelay += wordDelay
                }

            case .component(let id, _):
                allSegmentIds.append(id)

                DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                        _ = visibleSegments.insert(id)
                    }
                }
                currentDelay += wordDelay * 3 // Componentes tardan más en aparecer
            }
        }

        // Notificar cuando complete
        DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay + 0.3) {
            isComplete = true
            onComplete?()
        }
    }
}

/// Layout que fluye horizontalmente y se envuelve (como FlexBox)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if x + subviewSize.width > maxWidth && x > 0 {
                    // Nueva línea
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, subviewSize.height)
                x += subviewSize.width + spacing
            }

            size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview("Simple Text Streaming") {
    ZStack {
        Color.llegoBackground.ignoresSafeArea()

        VStack(alignment: .leading, spacing: 20) {
            StreamingTextView(
                text: "Quiero ordenar productos frescos del vendedor más cercano",
                font: .system(size: 20, weight: .regular),
                color: .onBackgroundColor
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Streaming with Components") {
    struct StreamingWithComponentsPreview: View {
        var body: some View {
            ZStack {
                Color.llegoBackground.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 12) {
                        // Avatar
                        Circle()
                            .fill(Color.llegoAccent)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                            )

                        // Burbuja de chat
                        VStack(alignment: .leading, spacing: 12) {
                            StreamingTextView(
                                segments: [
                                    .text("Quiero ordenar"),
                                    .component(id: "pill1", AnyView(
                                        Text("productos")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.llegoSurface)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                            )
                                    )),
                                    .text("del vendedor"),
                                    .component(id: "pill2", AnyView(
                                        Text("más cercano")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.llegoSurface)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                            )
                                    ))
                                ],
                                font: .system(size: 18, weight: .regular),
                                color: .onBackgroundColor,
                                wordDelay: 0.08
                            )
                        }
                        .padding(16)
                        .background(Color.llegoSurface)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 100)
            }
        }
    }

    return StreamingWithComponentsPreview()
}
