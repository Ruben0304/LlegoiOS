import SwiftUI

/// Versión simplificada de CategoryItem sin fondo circular
/// Usa las mismas imágenes que SemicircularSlider
struct SimpleCategoryItem: View {
    let text: String
    let imageName: String
    let imageSize: CGFloat

    init(text: String, imageName: String, imageSize: CGFloat = 60) {
        self.text = text
        self.imageName = imageName
        self.imageSize = imageSize
    }

    var body: some View {
        VStack(spacing: 6) {
            // Imagen sin fondo
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)

            // Texto
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.llegoPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: imageSize + 10)
    }
}

#Preview {
    HStack(spacing: 20) {
        SimpleCategoryItem(text: "Italiana", imageName: "italiana")
        SimpleCategoryItem(text: "Vegetariana", imageName: "vegetariana")
        SimpleCategoryItem(text: "Batidos y Cócteles", imageName: "batidos_y_cocteles")
    }
    .padding()
    .background(Color.llegoBackground)
}
