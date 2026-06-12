import Apollo
import SwiftUI

// MARK: - Creative models

/// A paid feed creative. The business designs a Canva-style card in LlegoBusiness
/// and exports it as a single photo; here we just show that image.
struct FeedCreativeItem: Identifiable, Hashable, Sendable {
    let id: String                // campaignId
    let campaignId: String
    let branchId: String
    let businessId: String
    let placement: String
    let imageUrl: String
    let ctaDeeplink: String?
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

// MARK: - Card used inside the feed carousels

struct CreativeCard: View {
    let item: FeedCreativeItem
    @Environment(\.colorScheme) private var colorScheme

    // Horizontal grande (3:2), foto exportada por el negocio.
    private let cardSize = CGSize(width: 320, height: 213)

    var body: some View {
        NavigationLink(destination: StoreDetailView(storeId: item.branchId)) {
            CachedAsyncImage(
                url: URL(string: item.imageUrl),
                cacheKey: "creative_\(item.campaignId)",
                displaySize: cardSize,
                content: { image in image.resizable().scaledToFill() },
                placeholder: { placeholder },
                failure: { placeholder }
            )
            .frame(width: cardSize.width, height: cardSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            AdTracking.click(item.campaignId)
        })
        .onAppear { AdTracking.impression(item.campaignId) }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#023133"), Color(hex: "#0A5C3F")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            ProgressView().tint(.white)
        }
    }
}
