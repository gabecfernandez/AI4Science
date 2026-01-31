import Foundation
import ResearchKit

/// Configures ResearchKit appearance and settings
enum ResearchKitConfiguration {
    // MARK: - Public Methods

    /// Configure ResearchKit appearance globally
    static func configure() {
        configureAppearance()
        configureColors()
        configureTypography()
    }

    // MARK: - Private Methods

    private static func configureAppearance() {
        // Configure task view controller appearance
        let taskAppearance = UIAppearance()

        // Configure navigation bar
        let navigationBar = UINavigationBar.appearance()
        navigationBar.tintColor = UIColor.systemBlue
        navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        // Configure bar button items
        let barButtonItem = UIBarButtonItem.appearance()
        barButtonItem.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ], for: .normal)
    }

    private static func configureColors() {
        // Configure ORK text colors
        ORKSkin.setColor(.primary, forColorKey: ORKColorKeywordPrimary)
        ORKSkin.setColor(.accent, forColorKey: ORKColorKeywordAccent)
        ORKSkin.setColor(.label, forColorKey: ORKColorKeywordLabel)
    }

    private static func configureTypography() {
        // Typography is automatically handled by system fonts
        // Customize as needed for your app
    }
}

// MARK: - Color Extensions
extension UIColor {
    static let accent = UIColor.systemBlue
    static let primary = UIColor.systemBlue
}

// MARK: - ORK Configuration Extensions
extension ORKSkin {
    /// Set color for specific color keyword
    static func setColor(_ color: UIColor, forColorKey key: String) {
        // This would integrate with ORK's color system
        // Implementation depends on ResearchKit version
    }
}

// MARK: - Color Keywords (ORK Compatibility)
enum ORKColorKeyword {
    static let primary = "ORKColorKeywordPrimary"
    static let accent = "ORKColorKeywordAccent"
    static let label = "ORKColorKeywordLabel"
}

// MARK: - Theme Configuration
struct ResearchKitTheme: Sendable {
    let primaryColor: UIColor
    let accentColor: UIColor
    let backgroundColor: UIColor
    let textColor: UIColor
    let secondaryTextColor: UIColor

    static let `default` = ResearchKitTheme(
        primaryColor: .systemBlue,
        accentColor: .systemGreen,
        backgroundColor: .systemBackground,
        textColor: .label,
        secondaryTextColor: .secondaryLabel
    )

    static let dark = ResearchKitTheme(
        primaryColor: .systemBlue,
        accentColor: .systemGreen,
        backgroundColor: .black,
        textColor: .white,
        secondaryTextColor: .lightGray
    )

    static let science = ResearchKitTheme(
        primaryColor: UIColor(red: 0.1, green: 0.3, blue: 0.6, alpha: 1.0),
        accentColor: UIColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0),
        backgroundColor: UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1.0),
        textColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
        secondaryTextColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
    )
}

// MARK: - Task Configuration
struct ResearchTaskConfiguration: Sendable {
    let identifier: String
    let title: String
    let description: String
    let estimatedDuration: TimeInterval
    let requiresConsent: Bool
    let allowSaveAndRestore: Bool

    init(
        identifier: String,
        title: String,
        description: String = "",
        estimatedDuration: TimeInterval = 0,
        requiresConsent: Bool = true,
        allowSaveAndRestore: Bool = false
    ) {
        self.identifier = identifier
        self.title = title
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.requiresConsent = requiresConsent
        self.allowSaveAndRestore = allowSaveAndRestore
    }
}

// MARK: - Accessibility Configuration
struct AccessibilityConfiguration: Sendable {
    static let enableLargeText = true
    static let enableVoiceOver = true
    static let minimumTapSize: CGFloat = 44

    static func configureAccessibility() {
        // Enable accessibility features
    }
}

// MARK: - Localization Configuration
struct LocalizationConfiguration: Sendable {
    static let supportedLanguages = ["en", "es", "fr", "de", "zh"]

    static func localizeTask(_ task: ORKTask) -> ORKTask {
        // Localize task titles and text based on current language
        return task
    }
}

// MARK: - Privacy Configuration
struct PrivacyConfiguration: Sendable {
    static let enableDataEncryption = true
    static let enableSecureStorage = true
    static let dataRetentionDays = 365

    static let privacyPolicy = """
        Your privacy is important to us. All data collected through this research app is:

        1. Encrypted during transmission and storage
        2. Stored on secure servers with restricted access
        3. Used only for research purposes
        4. Protected under HIPAA and GDPR regulations
        5. Never shared with third parties without consent

        You have the right to withdraw your data at any time.
        """

    static let termsOfUse = """
        By using this app, you agree to:

        1. Provide accurate information
        2. Follow study protocols
        3. Maintain the confidentiality of your participation
        4. Report any adverse events
        5. Comply with app usage policies
        """
}

// MARK: - Error Handling Configuration
struct ErrorHandlingConfiguration: Sendable {
    static let logErrors = true
    static let sendErrorReports = true
    static let displayUserFriendlyErrors = true
}
