import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var showPassword: Bool = false
    @State private var showRegisterView: Bool = false
    @FocusState private var focusedField: LoginField?

    enum LoginField {
        case email
        case password
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background moderno
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.llegoBackground,
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header con logo y título
                        headerSection
                            .padding(.top, 20)

                        // Formulario de login
                        loginFormSection
                            .padding(.top, 48)

                        // Divider con "o"
                        dividerSection
                            .padding(.vertical, 28)

                        // Apple Sign In
                        appleSignInSection

                        // Registro
                        registerSection
                            .padding(.top, 28)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 28)
                }

                // Loading overlay
                if case .loading = viewModel.state {
                    loadingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        dismiss()
                    })
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
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Logo con animación
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoPrimary,
                                Color.llegoPrimary.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                Text("L")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            VStack(spacing: 8) {
                // Título
                Text("Bienvenido")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.llegoPrimary)

                // Subtítulo
                Text("Inicia sesión para continuar")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 20) {
            // Email Field - Estilo iOS moderno
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .email ? .llegoPrimary : .gray)
                        .frame(width: 24)

                    TextField("Correo electrónico", text: $viewModel.email)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focusedField == .email ? Color.llegoPrimary : Color.clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
            }

            // Password Field - Estilo iOS moderno
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .password ? .llegoPrimary : .gray)
                        .frame(width: 24)

                    Group {
                        if showPassword {
                            TextField("Contraseña", text: $viewModel.password)
                                .font(.system(size: 16))
                        } else {
                            SecureField("Contraseña", text: $viewModel.password)
                                .font(.system(size: 16))
                        }
                    }
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            await viewModel.signIn()
                        }
                    }

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showPassword.toggle()
                        }
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focusedField == .password ? Color.llegoPrimary : Color.clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
            }

            // Forgot Password
            HStack {
                Spacer()
                Button(action: {
                    // TODO: Implementar recuperación de contraseña
                    print("Recuperar contraseña")
                }) {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.llegoButton)
                }
            }
            .padding(.top, -8)

            // Login Button - Estilo iOS moderno
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Iniciar Sesión")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if case .loading = viewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.isLoginButtonEnabled
                        ? LinearGradient(
                            gradient: Gradient(colors: [
                                Color.llegoButton,
                                Color.llegoButton.opacity(0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .cornerRadius(14)
                .shadow(
                    color: viewModel.isLoginButtonEnabled ? Color.llegoButton.opacity(0.4) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!viewModel.isLoginButtonEnabled)
            .padding(.top, 8)
        }
    }

    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)

            Text("o")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)

            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }

    // MARK: - Apple Sign In Section
    private var appleSignInSection: some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                Task {
                    await viewModel.signInWithApple(result: result)
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 56)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    // MARK: - Register Section
    private var registerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Text("¿No tienes una cuenta?")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)

                Button(action: {
                    showRegisterView = true
                }) {
                    Text("Regístrate")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.llegoPrimary)
                }
            }
        }
        .sheet(isPresented: $showRegisterView) {
            RegisterView(viewModel: viewModel)
        }
    }

    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                LottieView(name: "loading")
                    .frame(width: 120, height: 120)

                Text("Iniciando sesión...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.llegoPrimary)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(viewModel: ProfileViewModel())
}
