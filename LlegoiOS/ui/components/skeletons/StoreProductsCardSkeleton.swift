import SwiftUI

/// Skeleton elegante para StoreProductsCard durante la búsqueda
struct StoreProductsCardSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header skeleton
            HStack(spacing: 10) {
                // Logo skeleton
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .shimmer()
                
                // Info skeleton
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                        .frame(maxWidth: 120)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                        .frame(maxWidth: 160)
                        .shimmer()
                }
                
                Spacer()
                
                // Buttons skeleton
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .shimmer()
                    
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 36, height: 36)
                        .shimmer()
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // Products grid skeleton
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 140)
                        .shimmer()
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.gray.opacity(0.1),
                    Color.gray.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    StoreProductsCardSkeleton()
        .padding()
}
