import SwiftUI

struct ProjectSettingsView: View {
    let project: Project
    @State private var projectName: String = ""
    @State private var projectDescription: String = ""
    @State private var visibility: String = "private"
    @State private var allowDownload = true
    @State private var allowSharing = true
    @State private var showSaveConfirmation = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.09, green: 0.17, blue: 0.26),
                    Color(red: 0.12, green: 0.20, blue: 0.30)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Basic Information")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Project Name", systemImage: "folder.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            TextField("Project name", text: $projectName)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Description", systemImage: "doc.text.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            TextEditor(text: $projectDescription)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Permissions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Permissions")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Visibility", systemImage: "eye.fill")
                                .font(.subheadline)
                                .foregroundColor(.white)

                            Picker("Visibility", selection: $visibility) {
                                Text("Private").tag("private")
                                Text("Lab Only").tag("lab")
                                Text("Public").tag("public")
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: .infinity)
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Allow Downloads")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text("Members can download project data")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: $allowDownload)
                                .tint(.blue)
                        }

                        Divider()
                            .background(Color.white.opacity(0.1))

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Allow Sharing")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Text("Members can share project externally")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()

                            Toggle("", isOn: $allowSharing)
                                .tint(.blue)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    // Danger Zone
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Danger Zone")
                            .font(.headline)
                            .foregroundColor(.red)

                        Button(role: .destructive, action: {}) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Delete Project")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)

                        Text("This action cannot be undone")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(16)
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(12)

                    // Save button
                    Button(action: { showSaveConfirmation = true }) {
                        Text("Save Changes")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Spacer(minLength: 20)
                }
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            projectName = project.title
            projectDescription = project.description
        }
        .alert("Saved", isPresented: $showSaveConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Project settings updated successfully")
        }
    }
}

// Preview disabled - Project constructor mismatch
// #Preview {
//     ProjectSettingsView(...)
// }
