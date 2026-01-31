import SwiftUI

struct ProjectCreateView: View {
    let repository: ProjectRepository
    @Binding var isPresented: Bool
    let onCreated: () -> Void

    @State private var viewModel: ProjectFormViewModel?

    init(
        repository: ProjectRepository,
        isPresented: Binding<Bool>,
        onCreated: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self._isPresented = isPresented
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.background
                    .ignoresSafeArea()

                if let viewModel = viewModel {
                    projectFormContent(viewModel)
                } else {
                    LoadingView( "Loading...")
                }
            }
            .navigationTitle("Create Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await createProject() }
                    }
                    .disabled(!(viewModel?.isFormValid ?? false) || (viewModel?.isLoading ?? true))
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ProjectFormViewModel(mode: .create, repository: repository)
                }
            }
        }
        .interactiveDismissDisabled(viewModel?.isDirty ?? false)
    }

    @ViewBuilder
    private func projectFormContent(_ viewModel: ProjectFormViewModel) -> some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                projectFormFields(viewModel)
            }
            .padding(Spacing.base)
        }

        if viewModel.isLoading {
            loadingOverlay
        }
    }

    @ViewBuilder
    private func projectFormFields(_ viewModel: ProjectFormViewModel) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Title field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Project Title")
                    .font(Typography.labelMedium)
                    .foregroundColor(ColorPalette.onBackground)

                TextField("Enter project title", text: Binding(
                    get: { viewModel.title },
                    set: { viewModel.title = $0 }
                ))
                .textFieldStyle(.plain)
                .padding(Spacing.md)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(
                            viewModel.titleError != nil ? ColorPalette.error : ColorPalette.divider,
                            lineWidth: 1
                        )
                )
                .onChange(of: viewModel.title) {
                    viewModel.validateTitle()
                }

                HStack {
                    if let error = viewModel.titleError {
                        Text(error)
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.error)
                    }
                    Spacer()
                    Text("\(viewModel.titleCharacterCount)/100")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Description field
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Description")
                    .font(Typography.labelMedium)
                    .foregroundColor(ColorPalette.onBackground)

                TextEditor(text: Binding(
                    get: { viewModel.descriptionText },
                    set: { viewModel.descriptionText = $0 }
                ))
                .frame(minHeight: 100)
                .padding(Spacing.sm)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(
                            viewModel.descriptionError != nil ? ColorPalette.error : ColorPalette.divider,
                            lineWidth: 1
                        )
                )
                .scrollContentBackground(.hidden)
                .onChange(of: viewModel.descriptionText) {
                    viewModel.validateDescription()
                }

                HStack {
                    if let error = viewModel.descriptionError {
                        Text(error)
                            .font(Typography.labelSmall)
                            .foregroundColor(ColorPalette.error)
                    }
                    Spacer()
                    Text("\(viewModel.descriptionCharacterCount)/500")
                        .font(Typography.labelSmall)
                        .foregroundColor(ColorPalette.onSurfaceVariant)
                }
            }

            // Project Type picker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Project Type")
                    .font(Typography.labelMedium)
                    .foregroundColor(ColorPalette.onBackground)

                Picker("Project Type", selection: Binding(
                    get: { viewModel.projectType },
                    set: { viewModel.projectType = $0 }
                )) {
                    ForEach(ProjectType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(ColorPalette.surface)
                .cornerRadius(BorderStyles.radiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: BorderStyles.radiusMedium)
                        .stroke(ColorPalette.divider, lineWidth: 1)
                )
            }

            // Visibility picker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Visibility")
                    .font(Typography.labelMedium)
                    .foregroundColor(ColorPalette.onBackground)

                Picker("Visibility", selection: Binding(
                    get: { viewModel.visibility },
                    set: { viewModel.visibility = $0 }
                )) {
                    ForEach(ProjectVisibility.allCases, id: \.self) { visibility in
                        Text(visibility.displayName).tag(visibility)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Error message
            if let errorMessage = viewModel.saveErrorMessage {
                HStack {
                    IconAssets.error
                        .foregroundColor(ColorPalette.error)
                    Text(errorMessage)
                        .font(Typography.bodySmall)
                        .foregroundColor(ColorPalette.error)
                }
                .padding(Spacing.md)
                .background(ColorPalette.error.opacity(0.1))
                .cornerRadius(BorderStyles.radiusMedium)
            }
        }
        .padding(.bottom, Spacing.xl)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Creating project...")
                    .font(Typography.bodyMedium)
                    .foregroundColor(.white)
            }
            .padding(Spacing.xl)
            .background(ColorPalette.neutral_800)
            .cornerRadius(BorderStyles.radiusMedium)
        }
    }

    private func createProject() async {
        await viewModel?.save()
        if viewModel?.isSaved == true {
            onCreated()
            isPresented = false
        }
    }
}

// Preview disabled - requires SwiftData container setup
// #Preview {
//     ProjectCreateView(...)
// }
