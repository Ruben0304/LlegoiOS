import SwiftUI

struct LlegoSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search for 'Grocery'"
    var onValueChange: (String) -> Void = { _ in }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))

            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .onChange(of: text) { newValue in
                    onValueChange(newValue)
                }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive())
        .cornerRadius(24)
    }
}

#Preview {
    VStack(spacing: 20) {
        LlegoSearchBar(text: .constant(""))
        LlegoSearchBar(text: .constant("Pizza"))
    }
    .padding()
    .background(Color.llegoBackground)
}