import SwiftUI

struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    var action: (() -> Void)?

    var body: some View {
        Button(action: {
            if let action = action {
                action()
            } else {
                dismiss()
            }
        }) {
            Image(systemName: "chevron.left")
        }
    }
}

#Preview {
    NavigationStack {
        VStack {
            Text("Preview")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
    }
}
