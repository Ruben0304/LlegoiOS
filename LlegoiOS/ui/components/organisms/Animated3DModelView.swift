import SwiftUI
import SceneKit

struct Animated3DModelView: View {
    let modelName: String
    let cameraPosition: SCNVector3?
    let cameraEulerAngles: SCNVector3?
    let scaleEffect: CGFloat
    let slideOffset: CGFloat
    let carouselFloat: CGFloat
    let modelOpacity: Double
    let appeared: Bool

    var body: some View {
        GeometryReader { geometry in
            SceneKitView(
                modelName: modelName,
                cameraPosition: cameraPosition,
                cameraEulerAngles: cameraEulerAngles
            )
            .frame(width: geometry.size.width, height: 400)
            .scaleEffect(scaleEffect)
            .offset(
                x: slideOffset,
                y: appeared ? carouselFloat : 50
            )
            .opacity(appeared ? modelOpacity : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: scaleEffect)
            .clipped()
        }
        .frame(height: 400)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }
}
