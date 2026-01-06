import SwiftUI

/// Skeleton elegante para ProductCard durante la búsqueda
struct ProductCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image skeleton
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 150)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 4) {
                // Title skeleton (2 lines)
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 17)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 17)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 40)
                    .shimmer()
                
                // Shop name skeleton
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 13)
                    .frame(maxWidth: 100)
                    .shimmer()
            }
            
            // Price skeleton
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 18)
                .frame(maxWidth: 80)
                .shimmer()
        }
        .padding(16)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 26))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    ProductCardSkeleton()
        .padding()
}
