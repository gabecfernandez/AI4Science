//
//  NavigationCoordinator.swift
//  AI4Science
//
//  Centralized navigation management
//

import Foundation
import SwiftUI
import Observation

/// Coordinates navigation across all app tabs
@Observable
@MainActor
final class NavigationCoordinator {
    // MARK: - Navigation Paths
    var projectsPath = NavigationPath()
    var capturePath = NavigationPath()
    var analysisPath = NavigationPath()
    var researchPath = NavigationPath()
    var profilePath = NavigationPath()

    // MARK: - Modal State
    var presentedSheet: SheetDestination?
    var presentedFullScreenCover: FullScreenDestination?

    // MARK: - Tab Selection
    var selectedTab: AppTab = .projects

    // MARK: - Navigation Methods

    func showProjectDetail(_ projectId: UUID) {
        selectedTab = .projects
        projectsPath.append(ProjectDestination.detail(projectId))
    }

    func showProjectSamples(_ projectId: UUID) {
        selectedTab = .projects
        projectsPath.append(ProjectDestination.samples(projectId))
    }

    func showNewProject() {
        selectedTab = .projects
        projectsPath.append(ProjectDestination.newProject)
    }

    func showProjectEdit(_ projectId: UUID) {
        selectedTab = .projects
        projectsPath.append(ProjectDestination.edit(projectId))
    }

    func showCamera() {
        selectedTab = .capture
        capturePath.append(CaptureDestination.camera)
    }

    func showCaptureReview(_ captureId: UUID) {
        selectedTab = .capture
        capturePath.append(CaptureDestination.review(captureId))
    }

    func showAnnotationEditor(_ captureId: UUID) {
        selectedTab = .capture
        capturePath.append(CaptureDestination.annotate(captureId))
    }

    func showAnalysisResults(_ captureId: UUID) {
        selectedTab = .analysis
        analysisPath.append(AnalysisDestination.results(captureId))
    }

    func showComparisonView(_ captureIds: [UUID]) {
        selectedTab = .analysis
        analysisPath.append(AnalysisDestination.compare(captureIds))
    }

    func showSurvey(_ surveyId: String) {
        selectedTab = .research
        researchPath.append(ResearchDestination.survey(surveyId))
    }

    func showConsentFlow() {
        selectedTab = .research
        researchPath.append(ResearchDestination.consent)
    }

    func showSettings() {
        selectedTab = .profile
        profilePath.append(ProfileDestination.settings)
    }

    func showLabAffiliation() {
        selectedTab = .profile
        profilePath.append(ProfileDestination.labAffiliation)
    }

    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreenCover = destination
    }

    func dismissFullScreen() {
        presentedFullScreenCover = nil
    }

    func resetToRoot() {
        projectsPath = NavigationPath()
        capturePath = NavigationPath()
        analysisPath = NavigationPath()
        researchPath = NavigationPath()
        profilePath = NavigationPath()
    }

    func popToRoot(for tab: AppTab) {
        switch tab {
        case .projects:
            projectsPath = NavigationPath()
        case .capture:
            capturePath = NavigationPath()
        case .analysis:
            analysisPath = NavigationPath()
        case .research:
            researchPath = NavigationPath()
        case .profile:
            profilePath = NavigationPath()
        }
    }
}

// MARK: - Sheet Destinations

enum SheetDestination: Identifiable {
    case projectPicker
    case samplePicker(projectId: UUID)
    case modelSelector
    case exportOptions(captureIds: [UUID])

    var id: String {
        switch self {
        case .projectPicker:
            return "projectPicker"
        case .samplePicker(let id):
            return "samplePicker-\(id)"
        case .modelSelector:
            return "modelSelector"
        case .exportOptions(let ids):
            return "exportOptions-\(ids.count)"
        }
    }
}

// MARK: - Full Screen Destinations

enum FullScreenDestination: Identifiable {
    case camera(sampleId: UUID)
    case imageViewer(captureId: UUID)
    case videoPlayer(captureId: UUID)
    case arOverlay(captureId: UUID)

    var id: String {
        switch self {
        case .camera(let id):
            return "camera-\(id)"
        case .imageViewer(let id):
            return "imageViewer-\(id)"
        case .videoPlayer(let id):
            return "videoPlayer-\(id)"
        case .arOverlay(let id):
            return "arOverlay-\(id)"
        }
    }
}
