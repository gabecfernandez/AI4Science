import SwiftUI

struct ProjectEditView: View {
    let projectId: UUID
    @Environment(ServiceContainer.self) private var services
    @State private var project: Project?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let project = project {
                ProjectCreateView(editingProject: project)
            } else {
                Text("Project not found")
                    .foregroundStyle(ColorPalette.onSurfaceVariant)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            project = try? await services.projectRepository.findById(projectId)
            isLoading = false
        }
    }
}
