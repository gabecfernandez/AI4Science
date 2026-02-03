import SwiftUI

struct LoginView: View {
    @Environment(ServiceContainer.self) private var serviceContainer
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) var dismiss

    @State private var vm: LoginViewModel?

    var body: some View {
        Group {
            if let vm = vm {
                contentView(with: vm)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task {
            if vm == nil {
                vm = LoginViewModel(
                    authService: serviceContainer.authService,
                    appState: appState
                )
            }
        }
    }

    @ViewBuilder
    private func contentView(with vm: LoginViewModel) -> some View {
        @Bindable var vm = vm

        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.3),
                        Color(red: 0.15, green: 0.25, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "atom")
                                .font(.system(size: 48))
                                .foregroundColor(.white)

                            Text("AI4Science")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            Text("Scientific Research Platform")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)

                        // Form
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email Address", systemImage: "envelope.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextField("Enter your email", text: $vm.email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Password", systemImage: "lock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                SecureField("Enter your password", text: $vm.password)
                                    .textContentType(.password)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            // Remember me
                            Toggle("Remember me", isOn: $vm.rememberMe)
                                .tint(.blue)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Login button
                        Button(action: { Task { await vm.login() } }) {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty)
                        .opacity(vm.isLoading || vm.email.isEmpty || vm.password.isEmpty ? 0.6 : 1.0)

                        // Forgot password
                        if let _ = try? NSClassFromString("AI4Science.ForgotPasswordView") {
                            NavigationLink(destination: Text("Forgot Password (Placeholder)")) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Divider
                        HStack {
                            VStack { Divider() }
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            VStack { Divider() }
                        }
                        .foregroundColor(.white.opacity(0.3))

                        // Biometric login
                        Button(action: { Task { await vm.loginWithBiometric() } }) {
                            Label("Sign In with Face ID", systemImage: "faceid")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )

                        // Register link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            NavigationLink(destination: RegisterView()) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $vm.showError) {
                Button("OK") {
                    vm.showError = false
                }
            } message: {
                Text(vm.errorMessage)
            }
        }
    }
}

#Preview {
    LoginView()
}
