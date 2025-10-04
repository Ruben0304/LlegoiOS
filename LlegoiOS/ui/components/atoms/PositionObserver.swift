import SwiftUI

// PreferenceKey para observar posiciones
struct ViewPositionKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [String: CGPoint] = [:]

    static func reduce(value: inout [String: CGPoint], nextValue: () -> [String: CGPoint]) {
        value.merge(nextValue()) { $1 }
    }
}

// Extension para capturar y reportar la posición de una vista
extension View {
    func observePosition(id: String) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ViewPositionKey.self,
                    value: [id: geometry.frame(in: .global).center]
                )
            }
        )
    }
}

// Helper para obtener el centro de un CGRect
extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}