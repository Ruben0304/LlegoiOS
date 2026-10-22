import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = FavoritesViewModel()
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Fondo gradiente sutil sincronizado con ProductFeedView
                feedGradientBackground
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.8), value: gradientManager.currentCategoryIndex)
                if case .loading = viewModel.state {
                    loadingView
                } else if case .error(let message) = viewModel.state {
                    errorState(message: message)
                } else if viewModel.favoriteItems.isEmpty {
                    emptyFavoritesView
                } else {
                    favoritesList
                }
            }
            .navigationTitle("Favoritos")
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CloseButton(action: {
                        dismiss()
                    })
                }
            }
            .onAppear {
                viewModel.loadFavorites()
            }
            .onChange(of: favoritesManager.favoriteItemCount) { _, _ in
                viewModel.loadFavorites()
            }
        }
    }

    // MARK: - Feed Gradient Background
    private var feedGradientBackground: some View {
        let palette = gradientManager.getCurrentGradientPalette()

        return ZStack {
            // Base color - muy suave
            palette.veryLight
                .opacity(0.4)

            // Gradiente sutil
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: palette.light.opacity(0.15), location: 0.0),
                    .init(color: palette.veryLight.opacity(0.3), location: 0.4),
                    .init(color: Color.white.opacity(colorScheme == .dark ? 0.05 : 0.95), location: 1.0)
                ]),
                center: UnitPoint(x: 0.85, y: 0.15),
                startRadius: 10,
                endRadius: 600
            )
        }
    }

    private var favoritesList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(viewModel.favoriteItems) { item in
                    FavoriteItemCard(
                        item: item,
                        onAddToCart: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.addToCart(productId: item.id)
                        },
                        onRemove: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                viewModel.removeFavorite(productId: item.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(gradientManager.currentAccentColor)
            Text("Cargando favoritos...")
                .scaledFont(size: 16, weight: .medium, relativeTo: .body)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.6))
            Text(message)
                .scaledFont(size: 16, weight: .medium, relativeTo: .body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Reintentar") {
                viewModel.loadFavorites()
            }
            .frame(height: 50)
            .frame(maxWidth: 200)
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFavoritesView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                gradientManager.currentAccentColor.opacity(0.22),
                                gradientManager.currentAccentColor.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 92, height: 92)

                Image(systemName: "heart")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            VStack(spacing: 8) {
                Text("Aun no tienes favoritos")
                    .scaledFont(size: 22, weight: .semibold, design: .rounded, relativeTo: .title2)
                    .foregroundColor(.primary)

                Text("Agrega productos para verlos aqui")
                    .scaledFont(size: 15, weight: .regular, relativeTo: .subheadline)
                    .foregroundColor(.secondary.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 18)

            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "storefront")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Explorar productos")
                        .scaledFont(size: 15, weight: .bold, design: .rounded, relativeTo: .subheadline)
                }
                .frame(height: 44)
                .frame(maxWidth: 200)
            }
            .modifier(GlassProminentButtonModifier())
            .tint(gradientManager.currentAccentColor)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct GlassProminentButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glassProminent)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}

struct FavoriteItemCard: View {
    let item: FavoriteItem
    let onAddToCart: () -> Void
    let onRemove: () -> Void
    @ObservedObject private var gradientManager = GradientStateManager.shared

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(
                url: URL(string: item.imageUrl),
                content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: {
                    ProgressView()
                }
            )
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.thinMaterial)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .scaledFont(size: 15, weight: .bold, relativeTo: .subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.shop)
                        .scaledFont(size: 12, weight: .medium, relativeTo: .caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .scaledFont(size: 10, weight: .medium, relativeTo: .caption2)
                        .foregroundColor(.secondary)

                    Text(item.weight)
                        .scaledFont(size: 11, weight: .medium, relativeTo: .caption2)
                        .foregroundColor(.llegoAccent)
                }

                Text(item.formattedPrice)
                    .scaledFont(size: 15, weight: .bold, design: .rounded, relativeTo: .subheadline)
                    .foregroundColor(gradientManager.currentAccentColor)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onRemove) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Quitar de favoritos")

                Button(action: onAddToCart) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(gradientManager.currentAccentColor)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                        )
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Agregar al carrito")
                .disabled(!item.availability)
                .opacity(item.availability ? 1 : 0.4)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
