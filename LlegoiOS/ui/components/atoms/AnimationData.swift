import SwiftUI

struct AnimationData: Equatable {
    let imageUrl: String
    let startPosition: CGPoint
    let endPosition: CGPoint

    static func == (lhs: AnimationData, rhs: AnimationData) -> Bool {
        return lhs.imageUrl == rhs.imageUrl &&
               lhs.startPosition == rhs.startPosition &&
               lhs.endPosition == rhs.endPosition
    }
}