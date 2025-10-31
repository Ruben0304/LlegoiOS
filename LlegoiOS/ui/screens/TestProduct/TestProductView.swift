import SwiftUI

struct TestProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var imageLoaded = false

    // URL de la imagen de prueba
    private let imageURL = "https://www.the-girl-who-ate-everything.com/wp-content/uploads/2018/06/taco-pizza-recipe-003.jpg"

    var body: some View {
        ZStack {
            // Background with blur effect
            BackgroundImageWithBlur(imageURL: imageURL, imageLoaded: $imageLoaded)

            // Content overlay
//            VStack {
//
//                // Bottom content
//                VStack(alignment: .leading, spacing: 16) {
//                    // Brand/Source
//                    Text("Serious Eats")
//                        .font(.system(size: 14, weight: .medium))
//                        .foregroundColor(.white.opacity(0.8))
//
//                    // Product title
//                    Text("Foolproof Pan Pizza")
//                        .font(.system(size: 36, weight: .bold))
//                        .foregroundColor(.white)
//                        .lineLimit(2)
//
//                    // Author
//                    Text("J. Kenji López-Alt")
//                        .font(.system(size: 16, weight: .regular))
//                        .foregroundColor(.white.opacity(0.9))
//
//                    // Recipe info
//                    HStack(spacing: 24) {
//                        RecipeInfoItem(
//                            label: "TOTAL TIME",
//                            value: "10hr 45min"
//                        )
//
//                        RecipeInfoItem(
//                            label: "COOK TIME",
//                            value: "20min"
//                        )
//
//                        RecipeInfoItem(
//                            label: "YIELD",
//                            value: "4"
//                        )
//                    }
//                    .padding(.vertical, 8)
//
//                    // Read the story card
//                    Button(action: {
//                        // Navigate to story
//                    }) {
//                        HStack(spacing: 12) {
//                            // Thumbnail
//                            AsyncImage(url: URL(string: imageURL)) { image in
//                                image
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fill)
//                            } placeholder: {
//                                Color.gray.opacity(0.3)
//                            }
//                            .frame(width: 60, height: 60)
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("READ THE STORY")
//                                    .font(.system(size: 12, weight: .semibold))
//                                    .foregroundColor(.white.opacity(0.7))
//
//                                Text("Foolproof Pan Pizza")
//                                    .font(.system(size: 16, weight: .semibold))
//                                    .foregroundColor(.white)
//                            }
//
//                            Spacer()
//
//                            Image(systemName: "chevron.right")
//                                .font(.system(size: 14, weight: .semibold))
//                                .foregroundColor(.white.opacity(0.5))
//                        }
//                        .padding(16)
//                        .background(.ultraThinMaterial)
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                    }
//
//                    // Action buttons
//                    HStack(spacing: 12) {
//                        ActionButton(
//                            icon: "hand.thumbsup",
//                            title: "Cook",
//                            style: .primary
//                        )
//
//                        ActionButton(
//                            icon: "bookmark",
//                            title: "Save",
//                            style: .secondary
//                        )
//
//                        ActionButton(
//                            icon: "square.and.arrow.up",
//                            title: "Share",
//                            style: .secondary
//                        )
//                    }
//
//                    // Bottom indicator
//                    Capsule()
//                        .fill(.white.opacity(0.3))
//                        .frame(width: 40, height: 5)
//                        .frame(maxWidth: .infinity)
//                        .padding(.top, 8)
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 32)
//            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton(action: {
                    dismiss()
                })
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                CloseButton(action: {
                    dismiss()
                })
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Background Image with Blur Effect
struct BackgroundImageWithBlur: View {
    let imageURL: String
    @Binding var imageLoaded: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Imagen inferior (CON blur) - Ocupa toda la pantalla
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Color.black
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .blur(radius: 70) // Blur más pronunciado
                            .clipped()
                    case .failure:
                        Color.black
                    @unknown default:
                        Color.black
                    }
                }

                // Imagen superior (SIN blur) - Con máscara de gradiente
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .mask {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white, location: 0.0),
                                        .init(color: .white, location: 0.35),
                                        .init(color: .white.opacity(0.7), location: 0.45),
                                        .init(color: .white.opacity(0.3), location: 0.55),
                                        .init(color: .clear, location: 0.65)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                            .onAppear {
                                imageLoaded = true
                            }
                    default:
                        EmptyView()
                    }
                }
            }
            .overlay {
                // Gradient overlay for better text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.7),
                        .black.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Recipe Info Item
struct RecipeInfoItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)

            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let style: ActionButtonStyle

    enum ActionButtonStyle {
        case primary
        case secondary
    }

    var body: some View {
        Button {
            // Action
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style == .primary ? .ultraThickMaterial : .ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Preview
#Preview {
    TestProductView()
}
