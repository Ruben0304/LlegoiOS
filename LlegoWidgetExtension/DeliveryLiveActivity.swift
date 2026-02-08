import ActivityKit
import SwiftUI
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
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255))

                        Text(context.attributes.storeName)
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
                            Image(systemName: "storefront.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(
                                    Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255)
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
                            Image(systemName: "house.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(
                                    context.state.progressValue >= 1.0
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
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255))

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
            // Header: store name + distance
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.storeName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .lineLimit(1)

                        Text(context.state.statusDisplayText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
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
                Image(systemName: "storefront.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 124 / 255, green: 65 / 255, blue: 43 / 255))
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

                Image(systemName: "house.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(
                        context.state.progressValue >= 1.0
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
}
