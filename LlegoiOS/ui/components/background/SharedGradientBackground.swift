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
        // Colores base del gradiente
        let darkGreen = Color(red: 45/255, green: 85/255, blue: 65/255)
        let mediumGreen = Color(red: 80/255, green: 120/255, blue: 95/255)
        let lightGreen = Color(red: 150/255, green: 190/255, blue: 165/255)
        let veryLightGreen = Color(red: 180/255, green: 210/255, blue: 185/255)
        let lightGray = Color(red: 235/255, green: 235/255, blue: 235/255)
        let lighterGray = Color(red: 240/255, green: 240/255, blue: 240/255)

        // Estado inicial (expansionProgress = 0.0) - Gradiente original con verde arriba y gris abajo
        // Verde oscuro → Verde medio → Verde claro → Gris claro → Gris más claro
        // Ubicaciones: 0%, 25%, 40%, 50%, 100%

        // Estado final (expansionProgress = 1.0) - Todo verde, el verde baja hasta cubrir todo
        // Verde oscuro → Verde medio → Verde claro → Verde muy claro → Verde muy claro
        // Ubicaciones: 0%, 30%, 60%, 90%, 100%

        // Interpolar las ubicaciones de los stops
        let loc0 = 0.0
        let loc1 = 0.25 + (0.3 - 0.25) * expansionProgress
        let loc2 = 0.4 + (0.6 - 0.4) * expansionProgress
        let loc3 = 0.5 + (0.9 - 0.5) * expansionProgress
        let loc4 = 1.0

        // Interpolar los colores: en progress 0-0.5 usamos grises, en 0.5-1.0 transicionamos a verdes
        let color3 = expansionProgress < 0.5 ? lightGray : veryLightGreen
        let color4 = expansionProgress < 0.5 ? lighterGray : veryLightGreen

        return [
            .init(color: darkGreen, location: loc0),
            .init(color: mediumGreen, location: loc1),
            .init(color: lightGreen, location: loc2),
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
