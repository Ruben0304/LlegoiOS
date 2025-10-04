import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var showPassword: Bool = false
    @FocusState private var focusedField: RegisterField?

    enum RegisterField {
        case name
        case email
        case phone
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
                        // Header
                        headerSection
                            .padding(.top, 40)

                        // Formulario de registro
                        registerFormSection
                            .padding(.top, 40)

                        // Login link
                        loginLinkSection
                            .padding(.top, 32)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }

                // Loading overlay
                if case .loading = viewModel.state {
                    loadingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Volver")
                        }
                        .foregroundColor(.llegoPrimary)
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
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            Circle()
                .fill(Color.llegoPrimary)
                .frame(width: 70, height: 70)
                .overlay(
                    Text("L")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                )

            // Título
            Text("Crear cuenta")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.llegoPrimary)

            // Subtítulo
            Text("Completa tus datos para registrarte")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Register Form Section
    private var registerFormSection: some View {
        VStack(spacing: 16) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre completo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)

                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    TextField("Tu nombre completo", text: $viewModel.registerName)
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .email
                        }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focusedField == .name ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }

            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Correo electrónico")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.llegoPrimary)

                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    TextField("tu@email.com", text: $viewModel.registerEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .phone
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

            // Phone Field (Optional)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Teléfono")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.llegoPrimary)

                    Text("(opcional)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }

                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                        .frame(width: 20)

                    TextField("+53 5555 5555", text: $viewModel.registerPhone)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phone)
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
                        .stroke(focusedField == .phone ? Color.llegoPrimary : Color.gray.opacity(0.3), lineWidth: 1)
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
                        TextField("Mínimo 6 caracteres", text: $viewModel.registerPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                Task {
                                    await viewModel.register()
                                }
                            }
                    } else {
                        SecureField("Mínimo 6 caracteres", text: $viewModel.registerPassword)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit {
                                Task {
                                    await viewModel.register()
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

            // Register Button
            Button(action: {
                Task {
                    await viewModel.register()
                }
            }) {
                HStack {
                    Text("Crear cuenta")
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
                    viewModel.isRegisterButtonEnabled
                        ? Color.llegoButton
                        : Color.gray.opacity(0.3)
                )
                .cornerRadius(12)
            }
            .disabled(!viewModel.isRegisterButtonEnabled)
            .padding(.top, 8)

            // Terms and conditions
            Text("Al registrarte, aceptas nuestros términos y condiciones")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    // MARK: - Login Link Section
    private var loginLinkSection: some View {
        VStack(spacing: 12) {
            Text("¿Ya tienes una cuenta?")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Inicia sesión")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.llegoPrimary)
            }
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

                Text("Creando cuenta...")
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
    RegisterView(viewModel: ProfileViewModel())
}
