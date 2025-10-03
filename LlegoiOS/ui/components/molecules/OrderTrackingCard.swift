import SwiftUI

@available(iOS 26.0, *)
struct OrderTrackingCard: View {
    @Environment(\.tabViewBottomAccessoryPlacement) var placement
    var onTap: () -> Void

    var body: some View {
        if placement == .inline {
            // Full expanded view
            // Collapsed compact view
            HStack(spacing: 10) {
                // Compact delivery icon
                Image(systemName: "box.truck.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.llegoPrimary)

                VStack(alignment: .leading,spacing: 3 ){
                    // Compact info
                    Text("En camino")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.onBackgroundColor)
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.llegoAccent)
                            .frame(width: 5, height: 5)

                        Text("15 min")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.llegoPrimary)
                    }
                }

                Spacer()


                // Compact status
                Button(action: onTap) {
                    Text("Ver")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.llegoPrimary))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        } else {
            // Collapsed compact view
            HStack(spacing: 10) {
                // Compact delivery icon
                Image(systemName: "box.truck.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.llegoPrimary)

                VStack(alignment: .leading,spacing: 3 ){
                    // Compact info
                    Text("Pedido en camino")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.onBackgroundColor)
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.llegoAccent)
                            .frame(width: 5, height: 5)

                        Text("15 min")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.llegoPrimary)
                    }
                }

                Spacer()


                // Compact status
                Button(action: onTap) {
                    Text("Ver")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color.llegoPrimary))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
    }
}
