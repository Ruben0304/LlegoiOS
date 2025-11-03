import SwiftUI

struct SharedGradientBackground: View {
    var expansionProgress: Double = 1.0

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: gradientStops),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var gradientStops: [Gradient.Stop] {
        // Colores tomados del degradado de WelcomeView
        let deepGreen = Color(red: 0.05, green: 0.30, blue: 0.25)
        let emeraldGreen = Color(red: 0.10, green: 0.45, blue: 0.38)
        let softGreen = Color(red: 0.40, green: 0.65, blue: 0.55)
        let paleMint = Color(red: 0.85, green: 0.92, blue: 0.88)
        let softMint = Color(red: 0.95, green: 0.98, blue: 0.96)

        // Estado inicial (expansionProgress = 0.0) - Gradiente original con verde arriba y menta suave abajo
        // Verde profundo → Verde esmeralda → Verde suave → Menta suave → Menta suave
        // Ubicaciones: 0%, 25%, 40%, 50%, 100%

        // Estado final (expansionProgress = 1.0) - Todo verde, el verde baja hasta cubrir todo
        // Verde profundo → Verde esmeralda → Verde suave → Menta pálida → Menta pálida
        // Ubicaciones: 0%, 30%, 60%, 90%, 100%

        // Interpolar las ubicaciones de los stops
        let loc0 = 0.0
        let loc1 = 0.25 + (0.3 - 0.25) * expansionProgress
        let loc2 = 0.4 + (0.6 - 0.4) * expansionProgress
        let loc3 = 0.5 + (0.9 - 0.5) * expansionProgress
        let loc4 = 1.0

        // Interpolar los colores: en progress 0-0.5 usamos menta suave, en 0.5-1.0 transicionamos a menta pálida
        let color3 = expansionProgress < 0.5 ? softMint : paleMint
        let color4 = expansionProgress < 0.5 ? softMint : paleMint

        return [
            .init(color: deepGreen, location: loc0),
            .init(color: emeraldGreen, location: loc1),
            .init(color: softGreen, location: loc2),
            .init(color: color3, location: loc3),
            .init(color: color4, location: loc4)
        ]
    }
}

#Preview {
    VStack {
        SharedGradientBackground(expansionProgress: 0.0)
            .overlay(
                Text("Expansion: 0.0 (Contracted - Verde hasta 30%)")
                    .font(.headline)
                    .foregroundColor(.white)
            )

        SharedGradientBackground(expansionProgress: 0.5)
            .overlay(
                Text("Expansion: 0.5 (Mid - Verde hasta 65%)")
                    .font(.headline)
                    .foregroundColor(.white)
            )

        SharedGradientBackground(expansionProgress: 1.0)
            .overlay(
                Text("Expansion: 1.0 (Full - Verde 100%)")
                    .font(.headline)
                    .foregroundColor(.white)
            )
    }
}
