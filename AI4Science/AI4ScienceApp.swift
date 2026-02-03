//
//  AI4ScienceApp.swift
//  AI4Science
//
//  A citizen science platform for materials analysis
//  UTSA Vision & AI Lab
//
//  Created by Gabe Fernandez on 1/31/26.
//

import SwiftUI
import SwiftData

@main
struct AI4ScienceApp: App {
    // MARK: - State
    @State private var appState = AppState()
    @State private var navigationCoordinator = NavigationCoordinator()

    // MARK: - Model Container
    private let modelContainer: ModelContainer

    // MARK: - Services
    private let serviceContainer: ServiceContainer

    init() {
        // Configure SwiftData
        do {
            let schema = Schema([
                UserEntity.self,
                ProjectEntity.self,
                LabEntity.self,
                SampleEntity.self,
                CaptureEntity.self,
                AnnotationEntity.self,
                DefectEntity.self,
                AnalysisResultEntity.self,
                SyncMetadataEntity.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                cloudKitDatabase: .none
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }

        // Initialize service container
        serviceContainer = ServiceContainer(modelContainer: modelContainer)

        // Configure logging
        AppLogger.configure(level: .debug)
        AppLogger.shared.info("AI4Science app initialized")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(navigationCoordinator)
                .environment(serviceContainer)
                .modelContainer(modelContainer)
                .task {
                    await initializeApp()
                }
                .onOpenURL { url in
                    Task {
                        await handleOAuthCallback(url: url)
                    }
                }
        }
    }

    // MARK: - Initialization

    @MainActor
    private func initializeApp() async {
        AppLogger.shared.info("Starting app initialization")

        // Seed sample data if database is empty (development/demo only)
        let context = modelContainer.mainContext
        await SampleDataSeeder.seedIfEmpty(modelContext: context)
        await SampleDataSeeder.seedLabsIfNeeded(modelContext: context)
        await SampleDataSeeder.seedExtraLabMembersIfNeeded(modelContext: context)

        // Attempt Supabase session restore from Keychain
        if let restoredUser = await serviceContainer.authService.restoreSession() {
            appState.signIn(user: restoredUser)
        } else {
            await appState.checkAuthenticationState()
        }

        // Load cached ML models
        await serviceContainer.mlService.preloadModels()

        // Setup sync service
        await serviceContainer.syncService.configure()

        AppLogger.shared.info("App initialization complete")
    }

    @MainActor
    private func handleOAuthCallback(url: URL) async {
        guard url.scheme == "ai4science" else {
            AppLogger.shared.warning("Unrecognised URL scheme: \(url)")
            return
        }
        do {
            let user = try await serviceContainer.authService.handleGoogleOAuthCallback(url: url)
            appState.signIn(user: user)
        } catch {
            let appErr = (error as? AuthError)?.appError ?? .unknown(error.localizedDescription)
            appState.handleError(appErr)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(NavigationCoordinator.self) private var navigation

    var body: some View {
        Group {
            switch appState.authState {
            case .unknown:
                LaunchScreenView()
            case .unauthenticated:
                AuthenticationFlowView()
            case .authenticated:
                MainTabView()
            case .onboarding:
                OnboardingFlowView()
            }
        }
        .animation(.easeInOut, value: appState.authState)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(NavigationCoordinator.self) private var navigation
    @Environment(ServiceContainer.self) private var services
    @State private var selectedTab: AppTab = .labs

    var body: some View {
        @Bindable var nav = navigation

        TabView(selection: $selectedTab) {
            Tab("Labs", systemImage: "building.2.fill", value: .labs) {
                NavigationStack(path: $nav.labsPath) {
                    MyLabsView()
                        .navigationDestination(for: LabDestination.self) { destination in
                            destination.view(services: services)
                        }
                }
            }

            Tab("Projects", systemImage: "folder.fill", value: .projects) {
                ProjectListView()
            }

            Tab("Capture", systemImage: "camera.fill", value: .capture) {
                NavigationStack(path: $nav.capturePath) {
                    CaptureRootView()
                        .navigationDestination(for: CaptureDestination.self) { destination in
                            destination.view
                        }
                }
            }

            Tab("Analysis", systemImage: "waveform.path.ecg", value: .analysis) {
                NavigationStack(path: $nav.analysisPath) {
                    AnalysisDashboardView()
                        .navigationDestination(for: AnalysisDestination.self) { destination in
                            destination.view
                        }
                }
            }

            Tab("Research", systemImage: "testtube.2", value: .research) {
                NavigationStack(path: $nav.researchPath) {
                    ResearchDashboardView()
                        .navigationDestination(for: ResearchDestination.self) { destination in
                            destination.view
                        }
                }
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack(path: $nav.profilePath) {
                    ProfileRootView()
                        .navigationDestination(for: ProfileDestination.self) { destination in
                            destination.view
                        }
                }
            }
        }
    }
}

// MARK: - App Tab

enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case labs
    case projects
    case capture
    case analysis
    case research
    case profile

    var id: String { rawValue }
}

// MARK: - Launch Screen

struct LaunchScreenView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "atom")
                .font(.system(size: 80))
                .foregroundStyle(ColorPalette.primary)

            Text("AI4Science")
                .font(Typography.largeTitle)

            Text("UT San Antonio")
                .font(Typography.subheadline)
                .foregroundStyle(.secondary)

            ProgressView()
                .padding(.top, Spacing.xl)
        }
    }
}

// MARK: - Flow Views

struct AuthenticationFlowView: View {
    var body: some View {
        LoginView()
    }
}

struct OnboardingFlowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Text("Welcome to AI4Science")
                .font(Typography.title)

            Text("Complete your profile to get started")
                .font(Typography.body)
                .foregroundStyle(.secondary)

            PrimaryButton("Get Started") {
                appState.authState = .authenticated
            }
        }
        .padding()
    }
}

// MARK: - Root Views for Each Tab

struct CaptureRootView: View {
    var body: some View {
        CaptureListView()
    }
}

struct AnalysisDashboardView: View {
    var body: some View {
        AnalysisDashboardViewContent()
    }
}

struct ResearchDashboardView: View {
    var body: some View {
        ResearchDashboardViewContent()
    }
}

struct ProfileRootView: View {
    var body: some View {
        ProfileView()
    }
}

struct AppLoginView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "atom")
                .font(.system(size: 60))
                .foregroundStyle(ColorPalette.primary)

            Text("AI4Science")
                .font(Typography.title)

            Text("Sign in to continue")
                .font(Typography.body)
                .foregroundStyle(.secondary)

            PrimaryButton("Sign In (Demo)") {
                appState.authState = .authenticated
            }
            .padding(.top, Spacing.xl)
        }
        .padding()
    }
}

// MARK: - Navigation Destinations

enum ProjectDestination: Hashable {
    case detail(UUID)
    case samples(UUID)
    case newProject

    @ViewBuilder
    var view: some View {
        switch self {
        case .detail(let id):
            Text("Project Detail: \(id.uuidString.prefix(8))")
        case .samples(let projectId):
            Text("Samples for: \(projectId.uuidString.prefix(8))")
        case .newProject:
            Text("New Project")
        }
    }
}

enum CaptureDestination: Hashable {
    case camera
    case review(UUID)
    case annotate(UUID)

    @ViewBuilder
    var view: some View {
        switch self {
        case .camera:
            Text("Camera")
        case .review(let id):
            Text("Review: \(id.uuidString.prefix(8))")
        case .annotate(let id):
            Text("Annotate: \(id.uuidString.prefix(8))")
        }
    }
}

enum AnalysisDestination: Hashable {
    case results(UUID)
    case compare([UUID])

    @ViewBuilder
    var view: some View {
        switch self {
        case .results(let id):
            Text("Results: \(id.uuidString.prefix(8))")
        case .compare(let ids):
            Text("Compare: \(ids.count) items")
        }
    }
}

enum ResearchDestination: Hashable {
    case survey(String)
    case consent

    @ViewBuilder
    var view: some View {
        switch self {
        case .survey(let id):
            Text("Survey: \(id)")
        case .consent:
            Text("Consent")
        }
    }
}

enum ProfileDestination: Hashable {
    case settings
    case labAffiliation
    case exportData

    @ViewBuilder
    var view: some View {
        switch self {
        case .settings:
            Text("Settings")
        case .labAffiliation:
            Text("Lab Affiliation")
        case .exportData:
            Text("Export Data")
        }
    }
}

enum LabDestination: Hashable {
    case detail(String)    // labId
    case project(UUID)     // projectId

    @ViewBuilder
    func view(services: ServiceContainer) -> some View {
        switch self {
        case .detail(let labId):
            LabDetailView(labId: labId, labRepository: services.labRepository, projectRepository: services.projectRepository)
        case .project(let projectId):
            ProjectDetailView(projectId: projectId, repository: services.projectRepository)
        }
    }
}
