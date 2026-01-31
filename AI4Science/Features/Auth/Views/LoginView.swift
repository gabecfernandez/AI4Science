import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @Environment(\.dismiss) var dismiss

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

                                TextField("Enter your email", text: $viewModel.email)
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

                                SecureField("Enter your password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            // Remember me
                            Toggle("Remember me", isOn: $viewModel.rememberMe)
                                .tint(.blue)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
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
                                .foregroundColor(.blue)
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
