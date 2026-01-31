import Foundation
import ResearchKit

/// Configuration for survey questions and workflows
struct SurveyConfiguration: Sendable {
    let surveyIdentifier: String
    let title: String
    let description: String?
    let questions: [QuestionConfiguration]
    let allowPartialCompletion: Bool
    let estimatedDuration: TimeInterval
    let showProgressBar: Bool

    // MARK: - Initialization
    init(
        surveyIdentifier: String,
        title: String,
        description: String? = nil,
        questions: [QuestionConfiguration],
        allowPartialCompletion: Bool = false,
        estimatedDuration: TimeInterval = 0,
        showProgressBar: Bool = true
    ) {
        self.surveyIdentifier = surveyIdentifier
        self.title = title
        self.description = description
        self.questions = questions
        self.allowPartialCompletion = allowPartialCompletion
        self.estimatedDuration = estimatedDuration
        self.showProgressBar = showProgressBar
    }

    // MARK: - Static Methods

    static func onboarding() -> SurveyConfiguration {
        return SurveyConfiguration(
            surveyIdentifier: "onboardingSurvey",
            title: "Welcome Survey",
            description: "Tell us about yourself",
            questions: [
                QuestionConfiguration(
                    identifier: "ageRange",
                    text: "What is your age range?",
                    type: .singleChoice,
                    options: ["18-25", "26-35", "36-45", "46-55", "56-65", "65+"],
                    required: true
                ),
                QuestionConfiguration(
                    identifier: "experience",
                    text: "Research experience level",
                    type: .singleChoice,
                    options: ["Professional", "Academic", "Hobbyist", "Novice", "None"],
                    required: true
                ),
                QuestionConfiguration(
                    identifier: "interests",
                    text: "Research interests",
                    type: .multipleChoice,
                    options: ["Biology", "Chemistry", "Physics", "Environmental", "Other"],
                    required: false
                )
            ],
            estimatedDuration: 600
        )
    }

    static func demographics() -> SurveyConfiguration {
        return SurveyConfiguration(
            surveyIdentifier: "demographicsSurvey",
            title: "Demographic Information",
            description: "Help us understand our community",
            questions: [
                QuestionConfiguration(
                    identifier: "gender",
                    text: "Gender identity",
                    type: .singleChoice,
                    options: ["Male", "Female", "Non-binary", "Other", "Prefer not to answer"],
                    required: true
                ),
                QuestionConfiguration(
                    identifier: "ethnicity",
                    text: "Ethnicity/race",
                    type: .multipleChoice,
                    options: ["White", "Black", "Hispanic", "Asian", "Native American", "Other"],
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "education",
                    text: "Education level",
                    type: .singleChoice,
                    options: ["High School", "Bachelor's", "Master's", "PhD", "Other"],
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "location",
                    text: "Country/region",
                    type: .text,
                    required: false
                )
            ],
            estimatedDuration: 480
        )
    }

    static func satisfaction() -> SurveyConfiguration {
        return SurveyConfiguration(
            surveyIdentifier: "satisfactionSurvey",
            title: "Study Experience",
            description: "How was your experience?",
            questions: [
                QuestionConfiguration(
                    identifier: "overallSatisfaction",
                    text: "Overall satisfaction with the study",
                    type: .scale(min: 1, max: 5),
                    required: true
                ),
                QuestionConfiguration(
                    identifier: "easeOfUse",
                    text: "How easy was the study to complete?",
                    type: .scale(min: 1, max: 5),
                    required: true
                ),
                QuestionConfiguration(
                    identifier: "improvements",
                    text: "Suggestions for improvement",
                    type: .text,
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "recommend",
                    text: "Would you recommend this study?",
                    type: .boolean,
                    required: true
                )
            ],
            estimatedDuration: 300
        )
    }

    static func healthHistory() -> SurveyConfiguration {
        return SurveyConfiguration(
            surveyIdentifier: "healthHistorySurvey",
            title: "Health History",
            description: "Information for health-related research",
            questions: [
                QuestionConfiguration(
                    identifier: "conditions",
                    text: "Known medical conditions",
                    type: .text,
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "medications",
                    text: "Current medications",
                    type: .text,
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "allergies",
                    text: "Known allergies",
                    type: .text,
                    required: false
                ),
                QuestionConfiguration(
                    identifier: "familyHistory",
                    text: "Relevant family medical history",
                    type: .text,
                    required: false
                )
            ],
            allowPartialCompletion: true,
            estimatedDuration: 600
        )
    }
}

// MARK: - Question Configuration
struct QuestionConfiguration: Sendable {
    enum QuestionType: Sendable {
        case singleChoice
        case multipleChoice
        case text
        case scale(min: Int = 1, max: Int = 5)
        case boolean
        case date
        case time
    }

    let identifier: String
    let text: String
    let type: QuestionType
    let options: [String]
    let required: Bool
    let helpText: String?

    init(
        identifier: String,
        text: String,
        type: QuestionType,
        options: [String] = [],
        required: Bool = true,
        helpText: String? = nil
    ) {
        self.identifier = identifier
        self.text = text
        self.type = type
        self.options = options
        self.required = required
        self.helpText = helpText
    }
}

// MARK: - Builder Pattern
struct SurveyConfigurationBuilder {
    private var config: SurveyConfiguration

    init(surveyIdentifier: String, title: String) {
        self.config = SurveyConfiguration(
            surveyIdentifier: surveyIdentifier,
            title: title,
            questions: []
        )
    }

    mutating func setDescription(_ description: String) -> Self {
        var newConfig = config
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: description,
            questions: config.questions,
            allowPartialCompletion: config.allowPartialCompletion,
            estimatedDuration: config.estimatedDuration,
            showProgressBar: config.showProgressBar
        )
        return self
    }

    mutating func addQuestion(_ question: QuestionConfiguration) -> Self {
        var newConfig = config
        var questions = config.questions
        questions.append(question)
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: config.description,
            questions: questions,
            allowPartialCompletion: config.allowPartialCompletion,
            estimatedDuration: config.estimatedDuration,
            showProgressBar: config.showProgressBar
        )
        return self
    }

    mutating func addQuestions(_ questions: [QuestionConfiguration]) -> Self {
        var newConfig = config
        var allQuestions = config.questions
        allQuestions.append(contentsOf: questions)
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: config.description,
            questions: allQuestions,
            allowPartialCompletion: config.allowPartialCompletion,
            estimatedDuration: config.estimatedDuration,
            showProgressBar: config.showProgressBar
        )
        return self
    }

    mutating func setAllowPartialCompletion(_ allow: Bool) -> Self {
        var newConfig = config
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: config.description,
            questions: config.questions,
            allowPartialCompletion: allow,
            estimatedDuration: config.estimatedDuration,
            showProgressBar: config.showProgressBar
        )
        return self
    }

    mutating func setEstimatedDuration(_ duration: TimeInterval) -> Self {
        var newConfig = config
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: config.description,
            questions: config.questions,
            allowPartialCompletion: config.allowPartialCompletion,
            estimatedDuration: duration,
            showProgressBar: config.showProgressBar
        )
        return self
    }

    mutating func setShowProgressBar(_ show: Bool) -> Self {
        var newConfig = config
        newConfig = SurveyConfiguration(
            surveyIdentifier: config.surveyIdentifier,
            title: config.title,
            description: config.description,
            questions: config.questions,
            allowPartialCompletion: config.allowPartialCompletion,
            estimatedDuration: config.estimatedDuration,
            showProgressBar: show
        )
        return self
    }

    func build() -> SurveyConfiguration {
        return config
    }
}

// MARK: - Validation
extension SurveyConfiguration {
    func validate() -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if surveyIdentifier.isEmpty {
            issues.append(ValidationIssue(field: "surveyIdentifier", message: "Survey identifier cannot be empty"))
        }

        if title.isEmpty {
            issues.append(ValidationIssue(field: "title", message: "Survey title cannot be empty"))
        }

        if questions.isEmpty {
            issues.append(ValidationIssue(field: "questions", message: "Survey must contain at least one question"))
        }

        for (index, question) in questions.enumerated() {
            if question.text.isEmpty {
                issues.append(ValidationIssue(field: "question[\(index)].text", message: "Question text cannot be empty"))
            }
        }

        return issues
    }

    struct ValidationIssue: Sendable {
        let field: String
        let message: String
    }
}
