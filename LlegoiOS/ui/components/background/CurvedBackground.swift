import SwiftUI

struct CurvedBackground<Content: View>: View {
    let curveStartAbsolute: CGFloat
    let curveEndAbsolute: CGFloat
    let curveInclinationAbsolute: CGFloat
    let content: () -> Content

    init(
        curveStartAbsolute: CGFloat = 170,
        curveEndAbsolute: CGFloat = 170,
        curveInclinationAbsolute: CGFloat = 50,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.curveStartAbsolute = curveStartAbsolute
        self.curveEndAbsolute = curveEndAbsolute
        self.curveInclinationAbsolute = curveInclinationAbsolute
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height

            ZStack {
                // Background gray surface
                Color.llegoBackground
                    .ignoresSafeArea(.all)

                // Primary color curved background
                CurvedShape(
                    curveStart: curveStartAbsolute / height,
                    curveEnd: curveEndAbsolute / height,
                    curveInclination: curveInclinationAbsolute / height
                )
                .fill(Color.llegoPrimary)
                .ignoresSafeArea(.all)

                // Content on top
                content()
            }
        }
    }
}

struct CurvedShape: Shape {
    let curveStart: CGFloat
    let curveEnd: CGFloat
    let curveInclination: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let curveStartY = height * curveStart
        let curveEndY = height * curveEnd

        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Line to where curve starts
        path.addLine(to: CGPoint(x: 0, y: curveStartY))

        // Create curved path
        let curveHeight = height * curveInclination
        let controlPointY = curveStartY + curveHeight

        // Cubic curve that simulates a semicircle
        path.addCurve(
            to: CGPoint(x: width, y: curveEndY),
            control1: CGPoint(x: width * 0.25, y: controlPointY),
            control2: CGPoint(x: width * 0.75, y: controlPointY)
        )

        // Complete the rectangle
        path.addLine(to: CGPoint(x: width, y: 0))
        path.closeSubpath()

        return path
    }
}

#Preview {
    CurvedBackground {
        VStack {
            Text("Content goes here")
                .foregroundColor(.white)
                .font(.largeTitle)
            Spacer()
        }
        .padding()
    }
}