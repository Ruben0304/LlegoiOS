import SwiftUI

struct PromoSection: View {
    var onSubscriptionTap: () -> Void
    var onFamilyPaymentTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 8) {
                Text("Promociones especiales")
                    .font(.system(size: 22, weight: .semibold, design: .default))
                    .foregroundColor(Color.onBackgroundColor)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Promo cards horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Subscription promo card
                    SubscriptionPromoCard(onSubscribeTap: onSubscriptionTap)
                        .frame(width: UIScreen.main.bounds.width - 48)

                    // Family payment promo card
                    FamilyPaymentPromoCard(onTap: onFamilyPaymentTap)
                        .frame(width: UIScreen.main.bounds.width - 48)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    PromoSection(
        onSubscriptionTap: {
            print("Subscription tapped")
        },
        onFamilyPaymentTap: {
            print("Family payment tapped")
        }
    )
    .background(Color.llegoBackground)
}
