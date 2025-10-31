import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var selectedTab: AuthTab
    @State private var rememberMe = false
    @State private var showLoginPassword = false
    @State private var showRegisterPassword = false
    @FocusState private var focusedLoginField: LoginField?
    @FocusState private var focusedRegisterField: RegisterField?

    // Typewriter effect states
    @State private var displayedText = ""
    @State private var showCursor = true
    private let fullText = "Bienvenido a\nLlego"
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    private let primaryAccent = Color(red: 0.41, green: 0.62, blue: 0.52)

    init(viewModel: ProfileViewModel, startWithRegister: Bool = false) {
        self.viewModel = viewModel
        _selectedTab = State(initialValue: startWithRegister ? .register : .login)
    }

    enum AuthTab: CaseIterable {
        case login
        case register

        var title: String {
            switch self {
            case .login:
                return "Login"
            case .register:
                return "Register"
            }
        }
    }

    enum LoginField: Hashable {
        case email
        case password
    }

    enum RegisterField: Hashable {
        case name
        case email
        case phone
        case password
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .topLeading) {
                // Fondo primary completo
                Color.llegoPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Parte superior con header - Más arriba sin centrado vertical
                    headerSection
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    
                    // Parte blanca inferior - Ocupa el resto del espacio
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            authCard
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        Color.white
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 34,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 34,
                                    style: .continuous
                                )
                            )
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }

                if case .loading = viewModel.state {
                    loadingOverlay
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CloseButton {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onChange(of: selectedTab) { _ in
            focusedLoginField = nil
            focusedRegisterField = nil
            showLoginPassword = false
            showRegisterPassword = false
        }
    }

    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.05),
                Color(red: 0.13, green: 0.14, blue: 0.14)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .overlay(
            Canvas { context, size in
                let block: CGFloat = 90
                let spacing: CGFloat = 22
                let rectSize = block - spacing
                guard rectSize > 0 else { return }

                var y: CGFloat = 0
                while y < size.height + block {
                    var x: CGFloat = 0
                    while x < size.width + block {
                        let rect = CGRect(x: x, y: y, width: rectSize, height: rectSize)
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: 18),
                            with: .color(Color.white.opacity(0.035))
                        )
                        x += block
                    }
                    y += block
                }
            }
            .allowsHitTesting(false)
            .blendMode(.plusLighter)
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Título con efecto typewriter y cursor
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(displayedText)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(6)

                if showCursor && displayedText.count < fullText.count {
                    Text("|")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showCursor ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Subtítulo
            Text("Inicia sesión para disfrutar\nde la mejor experiencia")
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(Color.white.opacity(0.95))
                .lineSpacing(4)
                .opacity(displayedText == fullText ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: displayedText)
        }
        .onAppear {
            startTypewriterEffect()
            startCursorBlink()
        }
    }

    private var authCard: some View {
        VStack(spacing: 24) {
            segmentedControl

            if selectedTab == .login {
                loginForm
            } else {
                registerForm
            }
            socialSection
        }
    }

    private var segmentedControl: some View {
        Picker("Authentication", selection: $selectedTab) {
            ForEach(AuthTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .padding(.vertical, 6)
    }

    private var loginForm: some View {
        VStack(spacing: 18) {
            loginEmailField
            loginPasswordField

            rememberAndForgotRow

            primaryButton(
                title: "Login",
                isEnabled: viewModel.isLoginButtonEnabled
            ) {
                Task {
                    await viewModel.signIn()
                }
            }
        }
    }

    private var registerForm: some View {
        VStack(spacing: 18) {
            registerNameField
            registerEmailField
            registerPhoneField
            registerPasswordField

            primaryButton(
                title: "Register",
                isEnabled: viewModel.isRegisterButtonEnabled
            ) {
                Task {
                    await viewModel.register()
                }
            }

            Text("By continuing you agree to our terms and privacy policy.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
        }
    }

    private var socialSection: some View {
        VStack(alignment: .center, spacing: 18) {
            Text("Or login with")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.7))

            HStack(spacing: 16) {
                socialButton(title: "Google", accent: Color(red: 0.89, green: 0.25, blue: 0.21), symbol: "G") {
                    print("Google login tapped")
                }

                socialButton(title: "Facebook", accent: Color(red: 0.18, green: 0.38, blue: 0.78), symbol: "f") {
                    print("Facebook login tapped")
                }
            }
        }
    }

    private var rememberAndForgotRow: some View {
        HStack {
            Button {
                rememberMe.toggle()
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(primaryAccent, lineWidth: rememberMe ? 0 : 1)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(rememberMe ? primaryAccent : Color.clear)
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(rememberMe ? 1 : 0)
                        )

                    Text("Remember me")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                print("Forgot password tapped")
            } label: {
                Text("Forgot Password?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(primaryAccent)
            }
            .buttonStyle(.plain)
        }
    }

    private var loginEmailField: some View {
        authField(icon: "envelope.fill", isFocused: focusedLoginField == .email) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                TextField("", text: $viewModel.email, prompt: Text("Email Address").foregroundColor(.gray))
                    .font(.system(size: 16))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedLoginField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedLoginField = .password
                    }
            }
        }
    }

    private var loginPasswordField: some View {
        authField(icon: "lock.fill", isFocused: focusedLoginField == .password) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Group {
                    if showLoginPassword {
                        TextField("", text: $viewModel.password, prompt: Text("Password").foregroundColor(.gray))
                    } else {
                        SecureField("", text: $viewModel.password, prompt: Text("Password").foregroundColor(.gray))
                    }
                }
                .font(.system(size: 16))
                .focused($focusedLoginField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    Task {
                        await viewModel.signIn()
                    }
                }
            }
        } trailing: {
            Button {
                showLoginPassword.toggle()
            } label: {
                Image(systemName: showLoginPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private var registerNameField: some View {
        authField(icon: "person.fill", isFocused: focusedRegisterField == .name) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                TextField("", text: $viewModel.registerName, prompt: Text("Full Name").foregroundColor(.gray))
                    .font(.system(size: 16))
                    .textContentType(.name)
                    .focused($focusedRegisterField, equals: .name)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedRegisterField = .email
                    }
            }
        }
    }

    private var registerEmailField: some View {
        authField(icon: "envelope.fill", isFocused: focusedRegisterField == .email) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Email Address")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                TextField("", text: $viewModel.registerEmail, prompt: Text("Email Address").foregroundColor(.gray))
                    .font(.system(size: 16))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedRegisterField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedRegisterField = .phone
                    }
            }
        }
    }

    private var registerPhoneField: some View {
        authField(icon: "phone.fill", isFocused: focusedRegisterField == .phone) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Phone Number (optional)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                TextField("", text: $viewModel.registerPhone, prompt: Text("Phone Number").foregroundColor(.gray))
                    .font(.system(size: 16))
                    .keyboardType(.phonePad)
                    .focused($focusedRegisterField, equals: .phone)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedRegisterField = .password
                    }
            }
        }
    }

    private var registerPasswordField: some View {
        authField(icon: "lock.fill", isFocused: focusedRegisterField == .password) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)

                Group {
                    if showRegisterPassword {
                        TextField("", text: $viewModel.registerPassword, prompt: Text("Password (min. 6 characters)").foregroundColor(.gray))
                    } else {
                        SecureField("", text: $viewModel.registerPassword, prompt: Text("Password (min. 6 characters)").foregroundColor(.gray))
                    }
                }
                .font(.system(size: 16))
                .focused($focusedRegisterField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    Task {
                        await viewModel.register()
                    }
                }
            }
        } trailing: {
            Button {
                showRegisterPassword.toggle()
            } label: {
                Image(systemName: showRegisterPassword ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }

    private func authField<Content: View, Trailing: View>(
        icon: String,
        isFocused: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6).opacity(0.8))

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(primaryAccent)
            }
            .frame(width: 48, height: 48)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(isFocused ? primaryAccent : Color.black.opacity(0.05), lineWidth: isFocused ? 1.5 : 1)
        )
    }

    private func primaryButton(title: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                if case .loading = viewModel.state {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isEnabled ? primaryAccent : primaryAccent.opacity(0.4))
            )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.7)
    }

    private func socialButton(title: String, accent: Color, symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(symbol)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accent)
                    )

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.4)

                Text(selectedTab == .login ? "Signing in..." : "Creating account...")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(primaryAccent)
            )
        }
    }

    // MARK: - Typewriter Effect Functions

    private func startTypewriterEffect() {
        hapticGenerator.prepare()
        displayedText = ""

        Task {
            for character in fullText {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos por letra

                await MainActor.run {
                    displayedText.append(character)

                    // Vibración háptica por cada letra (excepto saltos de línea)
                    if character != "\n" {
                        hapticGenerator.impactOccurred()
                    }
                }
            }
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if displayedText == fullText {
                timer.invalidate()
                showCursor = false
            } else {
                showCursor.toggle()
            }
        }
    }
}

#Preview {
    LoginView(viewModel: ProfileViewModel())
}
