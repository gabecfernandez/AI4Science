import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
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

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)

                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Enter your email address and we'll send you a password reset link")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)

                // Email input
                VStack(alignment: .leading, spacing: 8) {
                    Label("Email Address", systemImage: "envelope.fill")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    TextField("Enter your email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                // Info box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text("Check your email for a reset link. It will expire in 24 hours.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Spacer()
                }
                .padding(12)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)

                Spacer()

                // Send button
                Button(action: { Task { await sendResetEmail() } }) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Reset Link")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading || email.isEmpty)
                .opacity(isLoading || email.isEmpty ? 0.6 : 1.0)

                // Back to login
                Button(action: { dismiss() }) {
                    Text("Back to Sign In")
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .foregroundColor(.blue)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Reset link sent! Check your email.")
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK") { showError = false }
        } message: { message in
            Text(message)
        }
    }

    private func sendResetEmail() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate API call
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        if email.lowercased() == "test@example.com" {
            showSuccess = true
        } else {
            errorMessage = "Email not found in our system"
            showError = true
        }
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView()
    }
}
