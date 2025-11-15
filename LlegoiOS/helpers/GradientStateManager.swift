import SwiftUI
import Combine

/// Manages the global gradient state across the application
/// When the category changes in WelcomeView, all views using WelcomeGradientBackground will update
@MainActor
class GradientStateManager: ObservableObject {
    /// Shared singleton instance
    static let shared = GradientStateManager()

    /// Current category index that determines the gradient colors
    @Published var currentCategoryIndex: Int = 0

    private init() {}

    /// Update the current category index
    func setCategoryIndex(_ index: Int) {
        currentCategoryIndex = index
    }
}
