import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services

    var body: some View {
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

                                TextField(
                                    "Email",
                                    text: $viewModel.email,
                                    prompt: Text("Enter your email").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Password", systemImage: "lock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                SecureField(
                                    "Password",
                                    text: $viewModel.password,
                                    prompt: Text("Enter your password").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textContentType(.password)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            // Remember me
                            HStack {
                                Text("Remember me")
                                    .foregroundColor(.white)
                                Spacer()
                                Capsule()
                                    .frame(width: 51, height: 31)
                                    .foregroundColor(viewModel.rememberMe
                                        ? Color(red: 0.4, green: 0.75, blue: 1.0)
                                        : Color.white.opacity(0.3))
                                    .overlay(
                                        Circle()
                                            .foregroundColor(.white)
                                            .frame(width: 27, height: 27)
                                            .offset(x: viewModel.rememberMe ? 10 : -10)
                                            .animation(.easeInOut(duration: 0.2), value: viewModel.rememberMe)
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.rememberMe.toggle()
                                        }
                                    }
                            }
                            .padding(.top, 8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)

                        // Login button
                        Button(action: { Task { await viewModel.login() } }) {
                            if viewModel.isLoading {
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
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                        .opacity(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty ? 0.6 : 1.0)

                        // Forgot password
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.subheadline)
                                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 1.0))
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
                        Button(action: { Task { await viewModel.loginWithBiometric() } }) {
                            Label("Sign In with Face ID", systemImage: "faceid")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .foregroundColor(Color(red: 0.4, green: 0.75, blue: 1.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.4, green: 0.75, blue: 1.0), lineWidth: 1)
                        )

                        // Register link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            NavigationLink(destination: RegisterView()) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.4, green: 0.75, blue: 1.0))
                            }
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 32)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.authService = services.authService
                viewModel.appState = appState
            }
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { viewModel.showError = false }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
}

#Preview {
    LoginView()
}
