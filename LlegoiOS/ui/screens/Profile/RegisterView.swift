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
                        // Header
                        headerSection
                            .padding(.top, 20)

                        // Formulario de registro
                        registerFormSection
                            .padding(.top, 36)

                        // Login link
                        loginLinkSection
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButton(action: {
                        presentationMode.wrappedValue.dismiss()
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
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.llegoPrimary.opacity(0.3), radius: 20, x: 0, y: 10)

                Text("L")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                // Título
                Text("Crear cuenta")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.llegoPrimary)

                // Subtítulo
                Text("Completa tus datos para comenzar")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Register Form Section
    private var registerFormSection: some View {
        VStack(spacing: 18) {
            // Name Field - Estilo iOS moderno
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .name ? .llegoPrimary : .gray)
                        .frame(width: 24)

                    TextField("Nombre completo", text: $viewModel.registerName)
                        .font(.system(size: 16))
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .email
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(focusedField == .name ? Color.llegoPrimary : Color.clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField)
            }

            // Email Field - Estilo iOS moderno
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .email ? .llegoPrimary : .gray)
                        .frame(width: 24)

                    TextField("Correo electrónico", text: $viewModel.registerEmail)
                        .font(.system(size: 16))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .phone
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

            // Phone Field (Optional) - Estilo iOS moderno
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16))
                        .foregroundColor(focusedField == .phone ? .llegoPrimary : .gray)
                        .frame(width: 24)

                    TextField("Teléfono (opcional)", text: $viewModel.registerPhone)
                        .font(.system(size: 16))
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phone)
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
                        .stroke(focusedField == .phone ? Color.llegoPrimary : Color.clear, lineWidth: 2)
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
                            TextField("Contraseña (mín. 6 caracteres)", text: $viewModel.registerPassword)
                                .font(.system(size: 16))
                        } else {
                            SecureField("Contraseña (mín. 6 caracteres)", text: $viewModel.registerPassword)
                                .font(.system(size: 16))
                        }
                    }
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            await viewModel.register()
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

            // Register Button - Estilo iOS moderno
            Button(action: {
                Task {
                    await viewModel.register()
                }
            }) {
                HStack(spacing: 8) {
                    Text("Crear cuenta")
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
                    viewModel.isRegisterButtonEnabled
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
                    color: viewModel.isRegisterButtonEnabled ? Color.llegoButton.opacity(0.4) : Color.clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            .disabled(!viewModel.isRegisterButtonEnabled)
            .padding(.top, 8)

            // Terms and conditions
            Text("Al registrarte, aceptas nuestros **términos y condiciones**")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
    }

    // MARK: - Login Link Section
    private var loginLinkSection: some View {
        HStack(spacing: 4) {
            Text("¿Ya tienes una cuenta?")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Inicia sesión")
                    .font(.system(size: 15, weight: .semibold))
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
