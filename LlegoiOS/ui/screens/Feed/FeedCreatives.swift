import Apollo
import SwiftUI

// MARK: - Creative models (mirror the backend CreativeSpec; both apps render this natively)

struct CreativeSpec: Hashable, Sendable {
    let aspectRatio: String       // "wide" | "square"
    let animationPreset: String   // none | fade_in | slide_in | pulse | gradient_shift | shine
    let background: Background
    let texts: [TextLayer]
    let badge: Badge?
    let cta: CTA?

    struct Background: Hashable, Sendable {
        let type: String          // solid | gradient | image
        let colors: [String]      // hex
        let angle: Int            // gradient angle (degrees)
        let imageUrl: String?     // presigned URL when type == "image"
    }

    struct TextLayer: Hashable, Sendable {
        let role: String          // eyebrow | title | subtitle | cta_label
        let value: String
        let color: String         // hex
        let size: String          // sm | md | lg | xl
        let weight: String        // regular | medium | bold
    }

    struct Badge: Hashable, Sendable {
        let text: String
        let style: String         // flash | discount | new | offer
    }

    struct CTA: Hashable, Sendable {
        let label: String
        let deeplink: String?
    }
}

struct FeedCreativeItem: Identifiable, Hashable, Sendable {
    let id: String                // campaignId
    let campaignId: String
    let branchId: String
    let businessId: String
    let placement: String
    let ctaDeeplink: String?
    let branchName: String?
    let branchAvatarUrl: String?
    let creative: CreativeSpec
}

struct FeedCreativeSection: Identifiable, Hashable, Sendable {
    let id: String                // sectionId
    let sectionId: String
    let title: String
    let items: [FeedCreativeItem]
}

// MARK: - Ad tracking (fire-and-forget)

enum AdTracking {
    static func impression(_ campaignId: String) {
        Task {
            do {
                _ = try await ApolloClientManager.shared.apollo.perform(
                    mutation: LlegoAPI.TrackAdImpressionMutation(id: campaignId))
            } catch {
                // Métricas best-effort; nunca afectan la UI.
            }
        }
    }

    static func click(_ campaignId: String) {
        Task {
            do {
                _ = try await ApolloClientManager.shared.apollo.perform(
                    mutation: LlegoAPI.TrackAdClickMutation(id: campaignId))
            } catch {}
        }
    }
}

// MARK: - Native renderer for a CreativeSpec

struct CreativeRenderView: View {
    let creative: CreativeSpec
    let size: CGSize
    let cacheKey: String

    @State private var pulse = false
    @State private var appeared = false
    @State private var shineX: CGFloat = -1
    @State private var gradientShift = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            background
            textStack
                .padding(16)
            if let badge = creative.badge {
                badgeView(badge)
                    .padding(12)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 8, x: 0, y: 4)
        .scaleEffect(pulse ? 1.03 : 1.0)
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : slideOffset)
        .onAppear(perform: startAnimation)
    }

    // MARK: Background

    @ViewBuilder
    private var background: some View {
        switch creative.background.type {
        case "image":
            if let url = creative.background.imageUrl {
                CachedAsyncImage(
                    url: URL(string: url),
                    cacheKey: cacheKey,
                    displaySize: size,
                    content: { image in image.resizable().scaledToFill() },
                    placeholder: { gradient },
                    failure: { gradient }
                )
                .frame(width: size.width, height: size.height)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.05), .black.opacity(0.45)],
                        startPoint: .top, endPoint: .bottom)
                )
            } else {
                gradient
            }
        case "solid":
            color(creative.background.colors.first ?? "#023133")
        default:
            gradient
        }
    }

    private var gradient: some View {
        let colors = creative.background.colors.isEmpty
            ? ["#023133", "#0A5C3F"] : creative.background.colors
        let (start, end) = Self.gradientPoints(creative.background.angle)
        return LinearGradient(
            colors: colors.map { Color(hex: $0) },
            startPoint: gradientShift ? end : start,
            endPoint: gradientShift ? start : end
        )
    }

    // MARK: Texts

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(creative.texts.enumerated()), id: \.offset) { _, t in
                Text(t.value)
                    .font(.system(size: Self.fontSize(t.size), weight: Self.fontWeight(t.weight)))
                    .foregroundColor(Color(hex: t.color))
                    .lineLimit(t.role == "title" ? 2 : 1)
                    .textCase(t.role == "eyebrow" ? .uppercase : nil)
                    .tracking(t.role == "eyebrow" ? 1.2 : 0)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
            }
            if let cta = creative.cta {
                Text(cta.label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.92)))
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .overlay(shineOverlay)
    }

    private func badgeView(_ badge: CreativeSpec.Badge) -> some View {
        Text(badge.text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(Self.badgeColor(badge.style)))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var shineOverlay: some View {
        if creative.animationPreset == "shine" {
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.35), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.5)
                .offset(x: shineX * geo.size.width)
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }
        }
    }

    // MARK: Animation

    private var slideOffset: CGFloat {
        creative.animationPreset == "slide_in" ? 40 : 0
    }

    private func startAnimation() {
        switch creative.animationPreset {
        case "fade_in":
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        case "slide_in":
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
        case "pulse":
            appeared = true
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { pulse = true }
        case "gradient_shift":
            appeared = true
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { gradientShift = true }
        case "shine":
            appeared = true
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false).delay(0.3)) { shineX = 1.2 }
        default:
            appeared = true
        }
    }

    // MARK: Helpers

    private func color(_ hex: String) -> some View { Color(hex: hex) }

    static func gradientPoints(_ angle: Int) -> (UnitPoint, UnitPoint) {
        let a = Double(angle) * .pi / 180
        let dx = cos(a) / 2, dy = sin(a) / 2
        return (UnitPoint(x: 0.5 - dx, y: 0.5 - dy), UnitPoint(x: 0.5 + dx, y: 0.5 + dy))
    }

    static func fontSize(_ size: String) -> CGFloat {
        switch size {
        case "sm": return 13
        case "lg": return 22
        case "xl": return 28
        default: return 16
        }
    }

    static func fontWeight(_ weight: String) -> Font.Weight {
        switch weight {
        case "bold": return .bold
        case "medium": return .medium
        default: return .regular
        }
    }

    static func badgeColor(_ style: String) -> Color {
        switch style {
        case "flash": return Color(hex: "#E53935")
        case "discount": return Color(hex: "#FB8C00")
        case "new": return Color(hex: "#43A047")
        default: return Color(hex: "#7C412B")  // offer
        }
    }
}

// MARK: - Card used inside the feed carousels

struct CreativeCard: View {
    let item: FeedCreativeItem
    @Environment(\.colorScheme) private var colorScheme

    private var cardSize: CGSize {
        item.creative.aspectRatio == "square"
            ? CGSize(width: 200, height: 200)
            : CGSize(width: 290, height: 150)
    }

    var body: some View {
        NavigationLink(destination: StoreDetailView(storeId: item.branchId)) {
            CreativeRenderView(
                creative: item.creative,
                size: cardSize,
                cacheKey: "creative_\(item.campaignId)"
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            AdTracking.click(item.campaignId)
        })
        .onAppear { AdTracking.impression(item.campaignId) }
    }
}
