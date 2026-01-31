import SwiftUI
import LocalAuthentication

struct BiometricPromptView: View {
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var biometricType: BiometricType = .faceID
    @Environment(\.dismiss) var dismiss

    enum BiometricType {
        case faceID
        case touchID
        case unknown
    }

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
                Spacer()

                // Icon
                Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                // Title and message
                VStack(spacing: 12) {
                    Text(biometricType == .faceID ? "Face ID" : "Touch ID")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Secure access to your research data")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Benefits
                VStack(spacing: 12) {
                    BiometricBenefit(
                        icon: "lock.shield.fill",
                        title: "Secure",
                        description: "Your biometric data never leaves your device"
                    )

                    BiometricBenefit(
                        icon: "bolt.fill",
                        title: "Fast",
                        description: "Instant authentication in seconds"
                    )

                    BiometricBenefit(
                        icon: "hand.thumbsup.fill",
                        title: "Convenient",
                        description: "No passwords to remember"
                    )
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)

                Spacer()

                // Enable button
                Button(action: { Task { await authenticateWithBiometric() } }) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Enable \(biometricType == .faceID ? "Face ID" : "Touch ID")")
                                .font(.headline)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(isLoading)

                // Skip button
                Button(action: { dismiss() }) {
                    Text("Skip for Now")
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
        .onAppear {
            detectBiometricType()
        }
        .alert("Error", isPresented: $showError, presenting: errorMessage) { _ in
            Button("OK") { showError = false }
        } message: { message in
            Text(message)
        }
    }

    private func detectBiometricType() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType == .faceID ? .faceID : .touchID
        }
    }

    private func authenticateWithBiometric() async {
        isLoading = true
        defer { isLoading = false }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = error?.localizedDescription ?? "Biometric authentication not available"
            showError = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Authenticate to enable biometric login"
            )

            if success {
                // Save biometric preference
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct BiometricBenefit: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()
        }
    }
}

#Preview {
    BiometricPromptView()
}
