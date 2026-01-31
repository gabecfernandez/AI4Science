import SwiftUI

struct ProjectCreateView: View {
    @Binding var isPresented: Bool
    @State private var viewModel = ProjectCreateViewModel()
    let onCreated: (Project) -> Void

    var body: some View {
        NavigationStack {
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
                        // Header
                        VStack(spacing: 8) {
                            Text("Create New Project")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Set up your research project")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Form
                        VStack(spacing: 16) {
                            // Project name
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Project Name", systemImage: "folder.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextField("Enter project name", text: $viewModel.projectName)
                                    .textInputAutocapitalization(.words)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }

                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Description", systemImage: "doc.text.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextEditor(text: $viewModel.projectDescription)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                            }

                            // Research area
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Research Area", systemImage: "atom")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Picker("Research Area", selection: $viewModel.researchArea) {
                                    Text("Materials Science").tag("materials")
                                    Text("Biology").tag("biology")
                                    Text("Chemistry").tag("chemistry")
                                    Text("Physics").tag("physics")
                                    Text("Engineering").tag("engineering")
                                    Text("Other").tag("other")
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .foregroundColor(.blue)
                            }

                            // Visibility
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Visibility", systemImage: "eye.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Picker("Visibility", selection: $viewModel.visibility) {
                                    Text("Private").tag("private")
                                    Text("Lab Only").tag("lab")
                                    Text("Public").tag("public")
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity)
                            }

                            // Collaborators
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Add Collaborators", systemImage: "person.2.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                TextField("Enter email addresses", text: $viewModel.collaborators)
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)

                                Text("Separate multiple emails with commas")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Create button
                        Button(action: { Task { await createProject() } }) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Project")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(viewModel.isLoading || viewModel.projectName.isEmpty)
                        .opacity(viewModel.isLoading || viewModel.projectName.isEmpty ? 0.6 : 1.0)

                        // Cancel button
                        Button(action: { isPresented = false }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Error", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("OK") { viewModel.showError = false }
        } message: { message in
            Text(message)
        }
    }

    private func createProject() async {
        guard !viewModel.projectName.isEmpty else {
            viewModel.errorMessage = "Project name is required"
            viewModel.showError = true
            return
        }

        await viewModel.createProject()

        if !viewModel.showError {
            let newProject = Project(
                id: UUID().uuidString,
                name: viewModel.projectName,
                description: viewModel.projectDescription,
                status: .active,
                sampleCount: 0,
                memberCount: 1,
                createdDate: Date()
            )
            onCreated(newProject)
            isPresented = false
        }
    }
}

#Preview {
    ProjectCreateView(isPresented: .constant(true)) { _ in }
}
