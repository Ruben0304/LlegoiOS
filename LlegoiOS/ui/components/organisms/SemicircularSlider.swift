import SwiftUI

struct SemicircularSlider: View {
    // Usando exactamente los mismos assets que commonMain
    let categories = [
        ("Italiana", "italiana"),
        ("Platos Fuertes", "platos_fuertes"),
        ("Vegetariana", "vegetariana"),
        ("Batidos y Cócteles", "batidos_y_cocteles"),
        ("Bebidas Enlatadas", "bebidas_enlatadas"),
        ("Botellas", "botellas")
    ]

    let containerHeight: CGFloat = 200
    let itemSize: CGFloat = 60
    let spacing: CGFloat = 20

    // Crear lista infinita para scroll continuo
    private var infiniteCategories: [(String, String)] {
        var result: [(String, String)] = []
        for _ in 0..<30 {
            result.append(contentsOf: categories)
        }
        return result
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenCenter = screenWidth / 2

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(Array(infiniteCategories.enumerated()), id: \.offset) { index, category in
                        GeometryReader { itemGeometry in
                            // Obtener la posición real del item en el ScrollView
                            let itemFrame = itemGeometry.frame(in: .named("scrollViewSpace"))
                            let itemCenter = itemFrame.midX
                            let distanceFromCenter = itemCenter - screenCenter

                            // Calcular curva elíptica con barriga hacia abajo (menos pronunciada)
                            let normalizedX = (distanceFromCenter / (screenWidth * 0.5)).clamped(to: -1.0...1.0)
                            let curveHeight: CGFloat = 50
                            let yOffset = sqrt(1 - normalizedX * normalizedX) * curveHeight

                            CategoryItem(
                                text: category.0,
                                imageName: category.1,
                                circleSize: itemSize
                            )
                            .offset(y: yOffset)
                        }
                        .frame(width: itemSize + 10, height: itemSize + 30)
                        }
                    }
                    .padding(.horizontal, screenWidth / 2)
                }
                .coordinateSpace(name: "scrollViewSpace")
                .onAppear {
                    // Scroll inicial hacia el centro para que no haya espacio vacío a la izquierda
                    let centerIndex = infiniteCategories.count / 2
                    proxy.scrollTo(centerIndex, anchor: .center)
                }
            }
        }
        .frame(height: containerHeight)
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    VStack {
        SemicircularSlider()
        Spacer()
    }
    .background(Color.llegoBackground)
    .ignoresSafeArea()
}