import SwiftUI

struct RecentOrderCard: View {
    let order: RecentOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Store image
                AsyncImage(url: URL(string: order.storeImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "storefront")
                        .foregroundColor(.gray)
                }
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.storeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(order.orderNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: order.status.icon)
                        .font(.caption)
                    Text(order.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(order.status.color.opacity(0.15))
                .foregroundColor(order.status.color)
                .cornerRadius(12)
            }
            
            Divider()
            
            // Items preview and total
            HStack(spacing: 8) {
                ForEach(order.items.prefix(3)) { item in
                    AsyncImage(url: URL(string: item.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if order.itemCount > 3 {
                    Text("+\(order.itemCount - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(order.formattedTotal)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(order.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
