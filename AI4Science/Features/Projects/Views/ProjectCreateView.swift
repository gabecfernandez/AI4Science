import SwiftUI

struct ProjectCreateView: View {
    @Environment(ServiceContainer.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ProjectCreateViewModel?
    @State private var showDiscardConfirmation = false

    let editingProject: Project?
    var onCompleted: ((Project) -> Void)?

    init(editingProject: Project?, onCompleted: ((Project) -> Void)? = nil) {
        self.editingProject = editingProject
        self.onCompleted = onCompleted
    }

    var body: some View {
        Form {
            if let vm = viewModel {
                nameSection(vm)
                descriptionSection(vm)
                researchAreaSection

                submitSection(vm)
            }
        }
        .navigationTitle(viewModel?.isEditMode == true ? "Edit Project" : "Create Project")
        .navigationBarBackButtonHidden(viewModel?.isDirty == true)
        .toolbar {
            if viewModel?.isDirty == true {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showDiscardConfirmation = true
                    }
                }
            }
        }
        .confirmationDialog("Discard Changes?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        }
        .task {
            if let project = editingProject {
                viewModel = ProjectCreateViewModel(repository: services.projectRepository, project: project)
            } else {
                viewModel = ProjectCreateViewModel(
                    repository: services.projectRepository,
                    ownerId: UUID() // In production, use authenticated user's ID
                )
            }
        }
        .alert("Error", isPresented: Binding(get: { viewModel?.showError ?? false }, set: { viewModel?.showError = $0 })) {
            Button("OK") { viewModel?.showError = false }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    // MARK: - Name Section

    private func nameSection(_ vm: ProjectCreateViewModel) -> some View {
        Section(header: Text("Project Name")) {
            TextField("Enter project name", text: Binding(get: { vm.name }, set: { vm.name = $0; vm.markDirty() }))
                .textInputAutocapitalization(.words)

            if let error = vm.nameValidationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ColorPalette.error)
            }
        }
    }

    // MARK: - Description Section

    private func descriptionSection(_ vm: ProjectCreateViewModel) -> some View {
        Section(header: Text("Description")) {
            TextEditor(text: Binding(get: { vm.description }, set: { vm.description = $0; vm.markDirty() }))
                .frame(minHeight: 80, maxHeight: 160)

            if let error = vm.descriptionValidationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ColorPalette.error)
            }
        }
    }

    // MARK: - Research Area (future use)

    private var researchAreaSection: some View {
        Section(header: Text("Research Area")) {
            Picker("Research Area", selection: .constant("materials")) {
                Text("Materials Science").tag("materials")
                Text("Biology").tag("biology")
                Text("Chemistry").tag("chemistry")
                Text("Physics").tag("physics")
                Text("Engineering").tag("engineering")
                Text("Other").tag("other")
            }
        }
    }

    // MARK: - Submit Section

    private func submitSection(_ vm: ProjectCreateViewModel) -> some View {
        Section {
            Button(action: { Task { await submitProject(vm) } }) {
                HStack {
                    Spacer()
                    if vm.isLoading {
                        ProgressView()
                    } else {
                        Text(vm.isEditMode ? "Save Changes" : "Create Project")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .foregroundStyle(Color.white)
            .background(vm.canSubmit ? ColorPalette.utsa_primary : ColorPalette.disabled)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(!vm.canSubmit || vm.isLoading)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        }
    }

    // MARK: - Actions

    private func submitProject(_ vm: ProjectCreateViewModel) async {
        if let project = await vm.submit() {
            onCompleted?(project)
            dismiss()
        }
    }
}
