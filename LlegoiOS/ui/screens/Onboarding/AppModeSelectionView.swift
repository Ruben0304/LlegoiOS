//
//  AppModeSelectionView.swift
//  LlegoiOS
//
//  Primera pantalla del onboarding: elegir entre modo elegante (con la vitrina
//  3D) y modo simple (catálogo directo). Las previsualizaciones son ilustraciones
//  abstractas dibujadas con SwiftUI — no fotos reales de la app.
//
//  El tamaño de las tarjetas sale del ancho de pantalla (UIScreen), no de un
//  GeometryReader: esta vista se presenta como overlay del onboarding, donde las
//  propuestas de tamaño no son fiables.
//
//  ⚠️ El layout evita a propósito tres cosas que hacían que AttributeGraph
//  detectara un ciclo ("Cycle detected through attribute") y dejara toda la
//  pantalla congelada — recibía toques pero no se volvía a dibujar nunca:
//
//  1. Leer los safe area insets de la UIWindow durante el body.
//  2. `ignoresSafeArea()` sobre el contenido siendo hermano del TabView del Home
//     (que a su vez publica insets). Ahora solo el fondo ignora el safe area.
//  3. `minimumScaleFactor` + `fixedSize` dentro de un VStack con Spacers que no
//     siempre cabe: la negociación de tamaño del texto podía oscilar.
//

import SwiftUI
import UIKit

struct AppModeSelectionView: View {
    /// Modo resaltado. La fuente de verdad es `AppModeManager.draftMode`, fuera
    /// del árbol de vistas: esta pantalla es un overlay que se re-crea, y con
    /// estado local (o del padre) la escritura se perdía — se sentía el háptico
    /// pero la tarjeta nunca cambiaba de aspecto.
    @ObservedObject private var modeManager = AppModeManager.shared

    /// Se llama con el modo elegido al pulsar "Continuar".
    let onContinue: (AppMode) -> Void

    private var selectedMode: AppMode { modeManager.draftMode }

    // Paleta de restaurantes (la misma familia terracota del carrusel del Home).
    private let accent = Color(red: 0.85, green: 0.33, blue: 0.21)
    private let accentSoft = Color(red: 0.95, green: 0.56, blue: 0.42)
    private let ink = Color(red: 0.17, green: 0.09, blue: 0.07)
    private let inkSecondary = Color(red: 0.45, green: 0.36, blue: 0.33)

    // MARK: - Medidas

    private static var screenSize: CGSize { UIScreen.main.bounds.size }

    private var cardWidth: CGFloat {
        max((Self.screenSize.width - 44 - 16) / 2, 120)
    }

    private var cardHeight: CGFloat {
        min(cardWidth / 0.72, Self.screenSize.height * 0.30)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 14)
                .padding(.horizontal, 24)

            Spacer(minLength: 12)

            HStack(alignment: .top, spacing: 16) {
                ForEach(AppMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        width: cardWidth,
                        height: cardHeight,
                        accent: accent,
                        ink: ink,
                        inkSecondary: inkSecondary
                    ) {
                        select(mode)
                    }
                }
            }

            Spacer(minLength: 10)

            summaryText
                .padding(.horizontal, 30)

            Spacer(minLength: 12)

            footer
                .padding(.horizontal, 28)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Solo el fondo se sale del safe area; el contenido lo respeta y así no
        // hay que consultar los insets de la ventana ni ignorarlos aquí.
        .background(background.ignoresSafeArea())
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color(red: 0.99, green: 0.965, blue: 0.955)

            // Halos suaves: dan profundidad sin competir con las tarjetas.
            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 95)
                .offset(x: -120, y: -230)

            Circle()
                .fill(accentSoft.opacity(0.22))
                .frame(width: 300, height: 300)
                .blur(radius: 105)
                .offset(x: 150, y: 250)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 11) {
            Text("LLEGÓ")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .tracking(3.6)
                .foregroundColor(accent.opacity(0.75))

            Text("¿Cómo quieres\nusar la app?")
                .font(.system(size: 33, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            Text("Puedes cambiarlo cuando quieras desde tu perfil.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Resumen del modo seleccionado

    private var summaryText: some View {
        Text(selectedMode.summary)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(inkSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .top)
            .animation(.easeInOut(duration: 0.2), value: selectedMode)
    }

    // MARK: - Footer

    private var footer: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onContinue(selectedMode)
        } label: {
            Text("Continuar")
                .font(.system(size: 18.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accent)
                )
                .shadow(color: accent.opacity(0.28), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(ModePressableButtonStyle())
    }

    // MARK: - Actions

    private func select(_ mode: AppMode) {
        guard mode != modeManager.draftMode else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
            modeManager.draftMode = mode
        }
    }
}

// MARK: - Tarjeta de modo

private struct ModeCard: View {
    let mode: AppMode
    let isSelected: Bool
    let width: CGFloat
    let height: CGFloat
    let accent: Color
    let ink: Color
    let inkSecondary: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            cardContent
                // El área tocable es todo el rectángulo de la tarjeta (incluidos
                // los huecos entre la maqueta y el texto), no solo las partes
                // opacas.
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // La tarjeta no elegida se apaga (tamaño, color y opacidad) para que la
        // selección se lea de un vistazo, no solo por el borde.
        .saturation(isSelected ? 1 : 0.55)
        .scaleEffect(isSelected ? 1 : 0.94)
        .opacity(isSelected ? 1 : 0.78)
        // Anima el cambio de selección aunque la escritura no venga dentro de un
        // withAnimation (p. ej. si el modo cambia desde fuera de esta pantalla).
        .animation(.spring(response: 0.36, dampingFraction: 0.78), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Modo \(mode.title)")
        .accessibilityHint(mode.summary)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var cardContent: some View {
            VStack(spacing: 12) {
                ZStack(alignment: .top) {
                    // Marco tipo dispositivo con la previsualización abstracta dentro
                    ModePreviewArt(mode: mode, accent: accent, width: width, height: height)
                        .frame(width: width, height: height)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    isSelected ? accent : Color.black.opacity(0.10),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? accent.opacity(0.20) : Color.black.opacity(0.06),
                            radius: isSelected ? 18 : 10,
                            x: 0,
                            y: isSelected ? 10 : 6
                        )

                    if mode.isRecommended {
                        Text("RECOMENDADO")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(accent))
                            .offset(y: -9)
                    }
                }
                .frame(width: width, height: height)

                VStack(spacing: 3) {
                    HStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? accent : Color.clear)
                                .frame(width: 20, height: 20)

                            Circle()
                                .stroke(
                                    isSelected ? accent : Color.black.opacity(0.22),
                                    lineWidth: 1.5
                                )
                                .frame(width: 20, height: 20)

                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(mode.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(ink)
                    }

                    Text(mode.tagline)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(inkSecondary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: width)
            }
            .frame(width: width)
    }
}

// MARK: - Ilustraciones abstractas (placeholder, no capturas reales)

private struct ModePreviewArt: View {
    let mode: AppMode
    let accent: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            switch mode {
            case .elegante:
                eleganteArt
            case .simple:
                simpleArt
            }
        }
        .frame(width: width, height: height)
    }

    // Vitrina 3D: un objeto flotando sobre un halo de color, con su sombra.
    private var eleganteArt: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.93, blue: 0.88),
                    Color(red: 0.96, green: 0.86, blue: 0.80),
                    Color(red: 0.99, green: 0.97, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color(red: 0.90, green: 0.45, blue: 0.32).opacity(0.35))
                .frame(width: width * 0.9, height: width * 0.9)
                .blur(radius: 26)
                .offset(y: -height * 0.06)

            VStack(spacing: 0) {
                Spacer().frame(height: height * 0.16)

                ZStack {
                    // Sombra proyectada del objeto
                    Ellipse()
                        .fill(Color.black.opacity(0.16))
                        .frame(width: width * 0.42, height: height * 0.035)
                        .blur(radius: 5)
                        .offset(y: height * 0.15)

                    // "Objeto 3D" abstracto: dos volúmenes superpuestos
                    RoundedRectangle(cornerRadius: width * 0.09, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.72, blue: 0.55),
                                    Color(red: 0.83, green: 0.36, blue: 0.24)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: width * 0.42, height: width * 0.42)
                        .rotationEffect(.degrees(-8))
                        .shadow(
                            color: Color(red: 0.6, green: 0.25, blue: 0.15).opacity(0.35),
                            radius: 10,
                            y: 6
                        )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.35)],
                                center: UnitPoint(x: 0.32, y: 0.28),
                                startRadius: 1,
                                endRadius: width * 0.22
                            )
                        )
                        .frame(width: width * 0.24, height: width * 0.24)
                        .offset(x: width * 0.15, y: -width * 0.14)
                }

                Spacer(minLength: 0)

                // Indicadores de categoría (el carrusel)
                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? Color.white : Color.white.opacity(0.6))
                            .frame(width: index == 0 ? 6 : 5, height: index == 0 ? 6 : 5)
                    }
                }
                .padding(.bottom, height * 0.09)

                // Línea de texto insinuada
                Capsule()
                    .fill(Color.black.opacity(0.14))
                    .frame(width: width * 0.52, height: 5)
                    .padding(.bottom, height * 0.08)
            }
        }
    }

    // Catálogo directo: selector de tipos arriba y rejilla de productos.
    private var simpleArt: some View {
        VStack(alignment: .leading, spacing: height * 0.028) {
            // Barra de tipos de negocio
            HStack(spacing: 4) {
                Capsule()
                    .fill(accent)
                    .frame(width: width * 0.26, height: height * 0.042)
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: width * 0.20, height: height * 0.042)
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: width * 0.20, height: height * 0.042)
            }
            .padding(.top, height * 0.08)

            // Rejilla de productos
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: width * 0.06) {
                    ForEach(0..<2, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 3) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.black.opacity(0.07))
                                .frame(height: height * 0.115)

                            Capsule()
                                .fill(Color.black.opacity(0.12))
                                .frame(width: width * 0.24, height: 4)

                            Capsule()
                                .fill(accent.opacity(0.5))
                                .frame(width: width * 0.14, height: 4)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, width * 0.09)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(Color.white)
    }
}

// MARK: - Button style

private struct ModePressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    AppModeSelectionView { _ in }
}
