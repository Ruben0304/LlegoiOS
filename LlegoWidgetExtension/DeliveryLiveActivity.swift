import ActivityKit
import SwiftUI
import UIKit
import WidgetKit

struct DeliveryLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DeliveryActivityAttributes.self) { context in
            // MARK: - Lock Screen / Banner UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island

                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        appLogoView(size: 18)
                        Text(headlineStatusText(context))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .foregroundStyle(.white)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(
                                    Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))

                            Text(context.state.remainingDistance)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        if context.state.estimatedMinutes > 0 {
                            Text("~\(context.state.estimatedMinutes) min")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    // Empty - spacing handled by leading/trailing
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Progress bar with icons
                        HStack(spacing: 0) {
                            // Store icon
                            activityAvatar(
                                imageData: context.attributes.storeImageData,
                                imageURL: context.attributes.storeImageUrl,
                                placeholderSystemName: "storefront.fill",
                                size: 20,
                                foreground: Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255)
                            )
                            .frame(width: 20)

                            // Progress track
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Capsule()
                                        .fill(.white.opacity(0.15))
                                        .frame(height: 3)

                                    // Filled progress
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(
                                                        red: 2 / 255, green: 49 / 255,
                                                        blue: 51 / 255),
                                                    Color(
                                                        red: 178 / 255, green: 214 / 255,
                                                        blue: 154 / 255),
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geometry.size.width
                                                * CGFloat(context.state.progressValue),
                                            height: 3
                                        )

                                    // Bicycle indicator
                                    Image(systemName: "bicycle")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(
                                            Color(
                                                red: 178 / 255, green: 214 / 255,
                                                blue: 154 / 255)
                                        )
                                        .offset(
                                            x: max(
                                                0,
                                                min(
                                                    geometry.size.width
                                                        * CGFloat(
                                                            context.state.progressValue) - 7,
                                                    geometry.size.width - 14
                                                )
                                            )
                                        )
                                }
                                .frame(height: 18)
                            }
                            .frame(height: 18)
                            .padding(.horizontal, 6)

                            // House icon
                            activityAvatar(
                                imageData: context.attributes.userAvatarData,
                                imageURL: context.attributes.userAvatarUrl,
                                placeholderSystemName: "house.fill",
                                size: 20,
                                foreground: context.state.progressValue >= 1.0
                                    ? Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255)
                                    : .gray
                            )
                            .frame(width: 20)
                        }

                        // Status text
                        Text(context.state.statusDisplayText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 4) {
                    activityAvatar(
                        imageData: context.attributes.storeImageData,
                        imageURL: context.attributes.storeImageUrl,
                        placeholderSystemName: "storefront.fill",
                        size: 14,
                        foreground: Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255)
                    )

                    Image(systemName: "bicycle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))
                        .symbolEffect(.pulse)
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                Text(context.state.remainingDistance)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))
                    .minimumScaleFactor(0.7)
            } minimal: {
                // MARK: - Minimal (when multiple activities)
                Image(systemName: "bicycle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<DeliveryActivityAttributes>)
        -> some View
    {
        VStack(spacing: 12) {
            // Header: app logo + status + distance
            HStack {
                HStack(spacing: 8) {
                    appLogoView(size: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(headlineStatusText(context))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(
                                Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))

                        Text(context.state.remainingDistance)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }

                    if context.state.estimatedMinutes > 0 {
                        Text("~\(context.state.estimatedMinutes) min")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar with store → bicycle → house
            HStack(spacing: 0) {
                activityAvatar(
                    imageData: context.attributes.storeImageData,
                    imageURL: context.attributes.storeImageUrl,
                    placeholderSystemName: "storefront.fill",
                    size: 24,
                    foreground: Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255)
                )
                .frame(width: 24)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.gray.opacity(0.25))
                            .frame(height: 3)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 2 / 255, green: 49 / 255, blue: 51 / 255),
                                        Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width
                                    * CGFloat(context.state.progressValue),
                                height: 3
                            )

                        Image(systemName: "bicycle")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(red: 2 / 255, green: 49 / 255, blue: 51 / 255))
                            .offset(
                                x: max(
                                    0,
                                    min(
                                        geometry.size.width
                                            * CGFloat(context.state.progressValue) - 8,
                                        geometry.size.width - 16
                                    )
                                )
                            )
                    }
                    .frame(height: 20)
                }
                .frame(height: 20)
                .padding(.horizontal, 8)

                activityAvatar(
                    imageData: context.attributes.userAvatarData,
                    imageURL: context.attributes.userAvatarUrl,
                    placeholderSystemName: "house.fill",
                    size: 24,
                    foreground: context.state.progressValue >= 1.0
                        ? Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255)
                        : .gray
                )
                .frame(width: 24)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255))
        .activitySystemActionForegroundColor(.white)
    }

    @ViewBuilder
    private func activityAvatar(
        imageData: Data?,
        imageURL: String?,
        placeholderSystemName: String,
        size: CGFloat,
        foreground: Color
    ) -> some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let imageURL, let url = URL(string: imageURL), !imageURL.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: placeholderSystemName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(size * 0.22)
                        .foregroundStyle(foreground)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Image(systemName: placeholderSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(size * 0.22)
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
        }
    }

    private func headlineStatusText(_ context: ActivityViewContext<DeliveryActivityAttributes>)
        -> String
    {
        let status = context.state.status.lowercased()
        if status == "delivered" || context.state.progressValue >= 1.0 {
            return "Entrega completada"
        }
        return "Pedido en camino"
    }

    @ViewBuilder
    private func appLogoView(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: size, height: size)

            Image(systemName: "shippingbox.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(size * 0.22)
                .foregroundStyle(Color(red: 178 / 255, green: 214 / 255, blue: 154 / 255))
                .frame(width: size, height: size)
        }
    }
}
