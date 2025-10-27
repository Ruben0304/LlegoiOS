//
//  OnboardingWatchView.swift
//  LeegoWatchOS Watch App
//
//  Created by Claude on 10/27/25.
//

import SwiftUI

struct OnboardingWatchView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var currentPage = 0

    let onboardingPages = [
        OnboardingWatchPage(
            title: "Llegó",
            subtitle: "Delivery en tu muñeca",
            icon: "bicycle.circle.fill",
            color: Color.llegoPrimary
        ),
        OnboardingWatchPage(
            title: "Rastrea",
            subtitle: "Sigue tu pedido en tiempo real",
            icon: "location.circle.fill",
            color: Color.llegoAccent
        ),
        OnboardingWatchPage(
            title: "Reordena",
            subtitle: "Repite tu último pedido fácilmente",
            icon: "arrow.clockwise.circle.fill",
            color: Color.llegoButton
        )
    ]

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<onboardingPages.count, id: \.self) { index in
                OnboardingWatchPageView(
                    page: onboardingPages[index],
                    isLastPage: index == onboardingPages.count - 1,
                    onContinue: {
                        if index < onboardingPages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            isOnboardingCompleted = true
                        }
                    }
                )
                .tag(index)
            }
        }
        .tabViewStyle(.verticalPage)
    }
}

struct OnboardingWatchPageView: View {
    let page: OnboardingWatchPage
    let isLastPage: Bool
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: geometry.size.height * 0.03) {
                Spacer()

                // Ícono principal con animación
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    page.color.opacity(0.3),
                                    page.color.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.45, height: geometry.size.width * 0.45)

                    Image(systemName: page.icon)
                        .font(.system(size: geometry.size.width * 0.22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    page.color,
                                    page.color.opacity(0.8)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                // Título
                Text(page.title)
                    .font(.system(size: geometry.size.width * 0.14, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                // Subtítulo
                Text(page.subtitle)
                    .font(.system(size: geometry.size.width * 0.075, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                    .padding(.horizontal, 8)

                Spacer()

                // Botón de continuar
                Button(action: onContinue) {
                    HStack(spacing: 6) {
                        Text(isLastPage ? "Comenzar" : "Siguiente")
                            .font(.system(size: geometry.size.width * 0.08, weight: .semibold))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Image(systemName: isLastPage ? "checkmark" : "arrow.right")
                            .font(.system(size: geometry.size.width * 0.07, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, geometry.size.height * 0.06)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        page.color,
                                        page.color.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.bottom, 5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct OnboardingWatchPage {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

#Preview {
    OnboardingWatchView(isOnboardingCompleted: .constant(false))
}
