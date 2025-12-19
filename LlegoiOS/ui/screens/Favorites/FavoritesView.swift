import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FavoritesViewModel()
    @ObservedObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
            .onChange(of: favoritesManager.favoriteItemCount) { _ in
                viewModel.loadFavorites()
            }
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
                .tint(.llegoPrimary)
            Text("Cargando favoritos...")
                .font(.system(size: 16, weight: .medium))
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Reintentar") {
                viewModel.loadFavorites()
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.llegoAccent)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyFavoritesView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.llegoAccent.opacity(0.22),
                                    Color.llegoPrimary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 92, height: 92)

                    Image(systemName: "heart")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                }

                VStack(spacing: 8) {
                    Text("Aun no tienes favoritos")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Agrega productos para verlos aqui")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 18)

                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "storefront")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Explorar productos")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.llegoAccent)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
                }
            }
            .padding(.vertical, 22)
            .frame(maxWidth: 520)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 140)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FavoriteItemCard: View {
    let item: FavoriteItem
    let onAddToCart: () -> Void
    let onRemove: () -> Void

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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.shop)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)

                    Text(item.weight)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.llegoAccent)
                }

                Text(item.formattedPrice)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.llegoPrimary)
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
                }

                Button(action: onAddToCart) {
                    Image(systemName: "cart.badge.plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(.thinMaterial)
                        )
                }
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
