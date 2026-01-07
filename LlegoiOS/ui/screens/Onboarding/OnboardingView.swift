import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isOnboardingCompleted: Bool

    let onboardingPages = [
        OnboardingPage(
            title: "Bienvenido a Llegó",
            subtitle: "Tu app de delivery favorita en Cuba",
            description: "",
            imageName: "onboarding2"
        ),
        OnboardingPage(
            title: "Delivery rápido",
            subtitle: "Entrega en tiempo récord",
            description: "Recibe tus pedidos en minutos. Nuestros repartidores están siempre listos para llevarte lo que necesitas",
            imageName: "onboarding"
        ),
//        OnboardingPage(
//            title: "Miles de productos",
//            subtitle: "Todo lo que necesitas en un solo lugar",
//            description: "Restaurantes, supermercados, farmacias y mucho más. Encuentra todo lo que buscas en Llegó",
//            imageName: "onboarding"
//        )
    ]

    var body: some View {
        ZStack {
            // Contenido principal del onboarding
            TabView(selection: $currentPage) {
                ForEach(0..<onboardingPages.count, id: \.self) { index in
                    OnboardingPageView(page: onboardingPages[index])
                        .tag(index)
                }

                // CategorySelectionView como última página del onboarding
               
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Indicadores de página y botones con fondo blanco y shape elegante
            // Solo mostrar si no estamos en la página de CategorySelection
            if currentPage < onboardingPages.count {
                VStack {
                    Spacer()

                    VStack(spacing: 25) {
                        // Indicadores de puntos modernos
                        HStack(spacing: 12) {
                            ForEach(0..<onboardingPages.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(index == currentPage ? Color.llegoPrimary : Color.gray.opacity(0.3))
                                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        .padding(.top, 25)

                        // Botones con diseño moderno
                        VStack(spacing: 16) {
                            if currentPage < onboardingPages.count - 1 {
                                // Botón "Siguiente" moderno
                                Button(action: {

                                        currentPage += 1

                                }) {
                                    HStack(spacing: 12) {
                                        Text("Siguiente")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))

                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .cornerRadius(28)

                                }.buttonStyle(.glassProminent)
                                .tint(Color.llegoButton)

                                // Botón "Saltar" moderno
                                Button(action: {
                                    currentPage = onboardingPages.count // Ir directamente a CategorySelectionView
                                }) {
                                    Text("Saltar")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(Color.gray)
                                        .padding(.vertical, 12)
                                }
                            } else {
                                // Botón "Continuar" para ir a CategorySelectionView
                                Button(action: {

                                        currentPage = onboardingPages.count

                                }) {
                                    HStack(spacing: 12) {
                                        Text("Continuar")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))

                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .cornerRadius(28)
                                    
                                }.buttonStyle(.glassProminent)
                                .tint(Color.llegoButton)
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 30)
                    .background(
                        ElegantBottomShape()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -10)
                            .ignoresSafeArea(edges: .bottom)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Imagen de fondo que sigue el shape elegante
                Image(page.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipShape(ImageClipShape())
                    .ignoresSafeArea()

                // Overlay con gradiente para mejorar legibilidad del texto
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                .clipShape(ImageClipShape())
                .ignoresSafeArea()

                // Contenido de texto
                VStack {
                    // Espacio superior pequeño para centrar mejor el texto
                    Spacer()
                        .frame(maxHeight: 100)

                    VStack(spacing: 20) {
                        Text(page.title)
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)

                        Text(page.subtitle)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.llegoAccent)
                            .multilineTextAlignment(.center)
                            .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)

                        Text(page.description)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
                    }
                    .padding(.horizontal, 40)

                    // Espacio inferior más grande para dar espacio a los botones
                    Spacer()
                        .frame(minHeight: 180)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
}

// Shape personalizado para el fondo inferior elegante
struct ElegantBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // Control de curva para hacer la forma más elegante
        let curveHeight: CGFloat = 40

        // Comienza desde la parte superior izquierda con una curva elegante
        path.move(to: CGPoint(x: 0, y: curveHeight))

        // Curva superior elegante usando múltiples puntos de control
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: 0),
            control1: CGPoint(x: width * 0.1, y: curveHeight * 0.3),
            control2: CGPoint(x: width * 0.2, y: 0)
        )

        // Curva del medio
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: curveHeight * 0.6),
            control1: CGPoint(x: width * 0.4, y: 0),
            control2: CGPoint(x: width * 0.6, y: curveHeight * 0.6)
        )

        // Curva final hacia la esquina superior derecha
        path.addCurve(
            to: CGPoint(x: width, y: 0),
            control1: CGPoint(x: width * 0.8, y: curveHeight * 0.6),
            control2: CGPoint(x: width * 0.9, y: 0)
        )

        // Línea hacia abajo por el lado derecho
        path.addLine(to: CGPoint(x: width, y: height))

        // Línea hacia la esquina inferior izquierda
        path.addLine(to: CGPoint(x: 0, y: height))

        // Cerrar el path
        path.closeSubpath()

        return path
    }
}

// Shape personalizado para recortar la imagen con la misma forma elegante
struct ImageClipShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        // Control de curva para hacer la forma más elegante
        let curveHeight: CGFloat = 40

        // Comienza desde la esquina superior izquierda
        path.move(to: CGPoint(x: 0, y: 0))

        // Línea superior
        path.addLine(to: CGPoint(x: width, y: 0))

        // Línea derecha
        path.addLine(to: CGPoint(x: width, y: height - curveHeight))

        // Curva final hacia la esquina inferior derecha (invertida)
        path.addCurve(
            to: CGPoint(x: width * 0.7, y: height - curveHeight * 0.6),
            control1: CGPoint(x: width * 0.9, y: height - curveHeight),
            control2: CGPoint(x: width * 0.8, y: height - curveHeight * 0.6)
        )

        // Curva del medio (invertida)
        path.addCurve(
            to: CGPoint(x: width * 0.3, y: height),
            control1: CGPoint(x: width * 0.6, y: height - curveHeight * 0.6),
            control2: CGPoint(x: width * 0.4, y: height)
        )

        // Curva superior elegante hacia la esquina inferior izquierda (invertida)
        path.addCurve(
            to: CGPoint(x: 0, y: height - curveHeight),
            control1: CGPoint(x: width * 0.2, y: height),
            control2: CGPoint(x: width * 0.1, y: height - curveHeight * 0.3)
        )

        // Línea izquierda
        path.addLine(to: CGPoint(x: 0, y: 0))

        // Cerrar el path
        path.closeSubpath()

        return path
    }
}

#Preview {
    OnboardingView(isOnboardingCompleted: .constant(false))
}
