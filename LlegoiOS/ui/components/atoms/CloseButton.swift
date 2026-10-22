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
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Cerrar")
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
