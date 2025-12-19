import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

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
    @State private var showEmailAuth = false // New state for toggling views
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

    // Altura esperada del título completo para evitar saltos de layout
    // Usamos el ancho de pantalla menos los paddings horizontales del header (24 + 24)
    private var expectedTitleHeight: CGFloat {
        let availableWidth = UIScreen.main.bounds.width - 48
        // Medimos el alto del texto completo con la misma fuente y lineSpacing
        let label = UILabel()
        label.numberOfLines = 0
        label.text = fullText
        label.font = UIFont.systemFont(ofSize: 48, weight: .bold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 6
        let attributed = NSAttributedString(
            string: fullText,
            attributes: [
                .font: label.font as Any,
                .paragraphStyle: paragraph
            ]
        )
        label.attributedText = attributed
        let size = label.sizeThatFits(CGSize(width: availableWidth, height: .greatestFiniteMagnitude))
        // Añadimos un pequeño margen para el cursor y variaciones
        return ceil(size.height) + 4
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Fondo primary completo
                WelcomeGradientBackground()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Parte superior con header - Más arriba sin centrado vertical
                    headerSection
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    // Parte blanca inferior - Ocupa el resto del espacio
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 32) {
                            authCard
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                    }
                    .padding(.top,32)
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
                            .ignoresSafeArea()
                    )
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                }

                if case .loading = viewModel.state {
                    loadingOverlay
                }
            }
            .navigationBarBackButtonHidden(true)
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
                    .fixedSize(horizontal: false, vertical: true)

                if showCursor && displayedText.count < fullText.count {
                    Text("|")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showCursor ? 1 : 0)
                }
            }
            // Reservamos el alto del texto completo desde el inicio para evitar saltos
            .frame(minHeight: expectedTitleHeight, alignment: .leading)

            // Subtítulo eliminado
        }
        .onAppear {
            startTypewriterEffect()
            startCursorBlink()
        }
    }

    private var authCard: some View {
        VStack(spacing: 24) {
            if showEmailAuth {
                // Email Auth Flow
                VStack(spacing: 24) {
                    // Back button to return to social options
                    Button {
                        withAnimation {
                            showEmailAuth = false
                            // Reset state if needed, but keeping text is usually fine
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Volver")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(Color.black.opacity(0.7))
                        .padding(.bottom, 8)
                    }
                    .buttonStyle(.plain)

                    segmentedControl

                    if selectedTab == .login {
                        loginForm
                    } else {
                        registerForm
                    }
                }
                .transition(.move(edge: .trailing))
            } else {
                // Landing Social Flow
                VStack(spacing: 20) {
                    // Apple Sign In
                    SignInWithAppleButton(.continue) { request in
                         request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await viewModel.signInWithApple(result: result)
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .environment(\.locale, Locale(identifier: "es"))
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                    
                    // Google Sign In
                    Button {
                        handleSignInButton()
                    } label: {
                        HStack(spacing: 12) {
                            Image("gicon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                            
                            Text("Continuar con Google")
                                .font(.system(size: 19, weight: .medium))
                                .foregroundColor(.black.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)

                    // Divider or Spacer
                    HStack {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                        Text("o")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Continue with Email
                    Button {
                        withAnimation {
                            showEmailAuth = true
                        }
                    } label: {
                        Text("O continuar con correo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    // Terms and Conditions Footer
                    Text("Al iniciar sesión, aceptas nuestros [Términos y Condiciones](https://llego.app/terms) y nuestra [Política de Privacidad](https://llego.app/privacy).")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 24)
                        .accentColor(Color.black.opacity(0.8)) // Color for the links
                }
                .transition(.move(edge: .leading))
            }
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

    // Old socialSection removed as requested
    
    private func handleSignInButton() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Error: Root View Controller not found")
            return
        }

        // Configurar Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "309268628843-vafbp3o66ul2ea1g2bo6h9bpraqk5sj0.apps.googleusercontent.com"
        )

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController) { signInResult, error in
            guard let result = signInResult else {
                if let error = error {
                     print("Google Sign In Error: \(error.localizedDescription)")
                     Task { @MainActor in
                         viewModel.errorMessage = "Error al iniciar sesión con Google: \(error.localizedDescription)"
                         viewModel.state = .unauthenticated
                     }
                }
                return
            }
            guard let idToken = result.user.idToken?.tokenString else {
                print("Google Sign In Error: idToken vacío")
                Task { @MainActor in
                    viewModel.errorMessage = "No se pudo obtener el token de Google"
                    viewModel.state = .unauthenticated
                }
                return
            }

            let authorizationCode = result.serverAuthCode
            let email = result.user.profile?.email

            print("Google Login Successful: \(email ?? "No Email")")
            Task { @MainActor in
                await viewModel.signInWithGoogle(
                    idToken: idToken,
                    authorizationCode: authorizationCode,
                    email: email
                )
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
