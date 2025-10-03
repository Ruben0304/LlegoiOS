import SwiftUI

struct CategoryItem: View {
    let text: String
    let imageName: String
    let circleSize: CGFloat

    init(text: String, imageName: String, circleSize: CGFloat = 80) {
        self.text = text
        self.imageName = imageName
        self.circleSize = circleSize
    }

    var body: some View {
        VStack(spacing: 8) {
            // Círculo con imagen
            ZStack {
                Circle()
                    .frame(width: circleSize, height: circleSize)
                    // .glassEffect(.regular.tint(Color.llegoSecondary))
                    .glassEffect(.regular.interactive())
                    .tint(Color.llegoSecondary)

                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: circleSize * 0.7, height: circleSize * 0.7)
            }

            // Texto
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundColor(Color(red: 27/255, green: 27/255, blue: 27/255))
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }

        .frame(width: circleSize + 10)
    }
}

#Preview {
    HStack(spacing: 20) {
        CategoryItem(text: "Italiana", imageName: "italiana")
        CategoryItem(text: "Vegetariana", imageName: "vegetariana")
        CategoryItem(text: "Platos Fuertes", imageName: "platos_fuertes")
    }
    .padding()
    .background(Color.llegoBackground)
}