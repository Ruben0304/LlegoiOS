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
                // Background
                Color.llegoBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header con logo y título
                        headerSection

                        // Formulario de login
                        loginFormSection
                            .padding(.top, 40)

                        // Divider con "o"
                        dividerSection
                            .padding(.vertical, 32)

                        // Apple Sign In
                        appleSignInSection

                        // Registro
                        registerSection
                            .padding(.top, 32)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
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
        VStack(spacing: 16) {
            // Logo
            Circle()
                .fill(Color.llegoPrimary)
                .frame(width: 80, height: 80)
                .overlay(
                    Text("L")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )

            // Título
            Text("Bienvenido a Llego")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.llegoPrimary)

            // Subtítulo
            Text("Inicia sesión para continuar")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
        }
    }

    // MARK: - Login Form Section
    private var loginFormSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo electrónico")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    TextField("tu@email.com", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .email ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)

                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    if showPassword {
                        TextField("Tu contraseña", text: $viewModel.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                Task {
                                    await viewModel.signIn()
                                }
                            }
                    } else {
                        SecureField("Tu contraseña", text: $viewModel.password)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                Task {
                                    await viewModel.signIn()
                                }
                            }
                    }

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .password ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            // Forgot Password
            HStack {
                Spacer()
                Button(action: {
                    // TODO: Implementar recuperación de contraseña
                    print("Recuperar contraseña")
                }) {
                    Text("¿Olvidaste tu contraseña?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoButton)
                }
            }

            // Login Button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack {
                    Text("Iniciar Sesión")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    if case .loading = viewModel.state {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    viewModel.isLoginButtonEnabled
                        ? Color.llegoButton
                        : Color.gray.opacity(0.3)
                )
                .cornerRadius(12)
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
        .frame(height: 54)
        .cornerRadius(12)
    }

    // MARK: - Register Section
    private var registerSection: some View {
        VStack(spacing: 12) {
            Text("¿No tienes una cuenta?")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Button(action: {
                showRegisterView = true
            }) {
                Text("Regístrate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.llegoPrimary, lineWidth: 2)
                    )
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
