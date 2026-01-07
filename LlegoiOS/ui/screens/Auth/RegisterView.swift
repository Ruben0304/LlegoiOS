import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: ProfileViewModel

    var body: some View {
        LoginView(viewModel: viewModel, startWithRegister: true)
    }
}

#Preview {
    RegisterView(viewModel: ProfileViewModel())
}
