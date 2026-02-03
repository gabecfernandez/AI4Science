import SwiftUI

struct RegisterView: View {
    @State private var viewModel = RegisterViewModel()
    @Environment(\.dismiss) var dismiss
    @Environment(AppState.self) private var appState
    @Environment(ServiceContainer.self) private var services

    var body: some View {
        NavigationStack {
            ZStack {
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
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Join the scientific research community")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)

                        // Form
                        VStack(spacing: 16) {
                            // Full name
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Full Name", systemImage: "person.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextField(
                                    "Full Name",
                                    text: $viewModel.fullName,
                                    prompt: Text("First and last name").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textContentType(.name)
                                    .textInputAutocapitalization(.words)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            // Email
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
                                    .onChange(of: viewModel.email) { _, newValue in
                                        viewModel.validateEmail(newValue)
                                    }

                                if !viewModel.emailValidationMessage.isEmpty {
                                    Text(viewModel.emailValidationMessage)
                                        .font(.caption)
                                        .foregroundColor(viewModel.isEmailValid ? .green : .red)
                                }
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Password", systemImage: "lock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                SecureField(
                                    "Password",
                                    text: $viewModel.password,
                                    prompt: Text("Create password").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textContentType(.newPassword)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                                    .onChange(of: viewModel.password) { _, newValue in
                                        viewModel.validatePassword(newValue)
                                    }

                                PasswordStrengthIndicator(strength: viewModel.passwordStrength)
                            }

                            // Confirm password
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Confirm Password", systemImage: "lock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                SecureField(
                                    "Confirm",
                                    text: $viewModel.confirmPassword,
                                    prompt: Text("Confirm password").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textContentType(.newPassword)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            // Institution field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Institution", systemImage: "building.2.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextField(
                                    "Institution",
                                    text: $viewModel.institution,
                                    prompt: Text("Your institution").foregroundStyle(.white.opacity(0.5))
                                )
                                    .textInputAutocapitalization(.sentences)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8)
                            }

                            // Terms checkbox
                            HStack(spacing: 12) {
                                Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(viewModel.agreedToTerms
                                        ? Color(red: 0.4, green: 0.75, blue: 1.0)
                                        : Color.white.opacity(0.4))
                                    .font(.title3)
                                    .onTapGesture { viewModel.agreedToTerms.toggle() }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("I agree to the")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    + Text(" Terms of Service ")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    + Text("and")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    + Text(" Privacy Policy")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }

                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)

                        // Register button
                        Button(action: { Task { await viewModel.register() } }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .opacity(!viewModel.isFormValid || viewModel.isLoading ? 0.6 : 1.0)

                        // Sign in link
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.white.opacity(0.7))
                            Button("Sign In") { dismiss() }
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.4, green: 0.75, blue: 1.0))
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
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

struct PasswordStrengthIndicator: View {
    let strength: RegisterViewModel.PasswordStrength

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(color(for: index))
                    .frame(height: 4)
            }
        }
        .padding(.top, 4)
    }

    private func color(for index: Int) -> Color {
        switch strength {
        case .weak:
            return index == 0 ? .red : .gray.opacity(0.3)
        case .fair:
            return index < 2 ? .orange : .gray.opacity(0.3)
        case .good:
            return index < 3 ? .yellow : .gray.opacity(0.3)
        case .strong:
            return .green
        }
    }
}

#Preview {
    RegisterView()
}
