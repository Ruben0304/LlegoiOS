import SwiftUI

struct CloseButton: View {
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
            Image(systemName: "xmark")
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
                CloseButton()
            }
        }
    }
}
