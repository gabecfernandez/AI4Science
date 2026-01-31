import Foundation
import ResearchKit

/// Task for initial onboarding survey
struct OnboardingSurveyTask: Sendable {
    // MARK: - Properties
    let identifier = "onboardingSurvey"
    let title = "Welcome to AI4Science"

    // MARK: - Methods

    /// Build the onboarding survey task
    func buildTask() throws -> ORKTask {
        var steps: [ORKStep] = []

        // Welcome step
        let welcomeStep = InstructionStepFactory.createInstructionStep(
            identifier: "onboarding_welcome",
            title: "Welcome to AI4Science",
            text: "Thank you for joining our research community. This survey will help us understand your background and research interests."
        )
        steps.append(welcomeStep)

        // Research experience
        let experienceStep = ORKQuestionStep(
            identifier: "researchExperience",
            title: "Research Experience",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Professional Researcher", value: "professional"),
                    ORKTextChoice(text: "Academic (Student/Faculty)", value: "academic"),
                    ORKTextChoice(text: "Hobbyist Researcher", value: "hobbyist"),
                    ORKTextChoice(text: "Novice with Interest", value: "novice"),
                    ORKTextChoice(text: "No Prior Experience", value: "none")
                ]
            )
        )
        experienceStep.text = "What best describes your research experience?"
        steps.append(experienceStep)

        // Research interests
        let interestStep = ORKQuestionStep(
            identifier: "researchInterests",
            title: "Research Interests",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Biology", value: "biology"),
                    ORKTextChoice(text: "Chemistry", value: "chemistry"),
                    ORKTextChoice(text: "Environmental Science", value: "environment"),
                    ORKTextChoice(text: "Physics", value: "physics"),
                    ORKTextChoice(text: "Computer Science", value: "cs"),
                    ORKTextChoice(text: "Medicine/Health", value: "medicine"),
                    ORKTextChoice(text: "Agriculture", value: "agriculture"),
                    ORKTextChoice(text: "Other", value: "other")
                ]
            )
        )
        interestStep.text = "Which research areas interest you? (Select all that apply)"
        steps.append(interestStep)

        // AI/ML experience
        let aiExperienceStep = ORKQuestionStep(
            identifier: "aiExperience",
            title: "AI and Machine Learning Experience",
            answer: ORKAnswerFormat.scale(
                withMaximumValue: 5,
                minimumValue: 1,
                defaultValue: 3,
                step: 1,
                vertical: false,
                maximumValueDescription: "Very Experienced",
                minimumValueDescription: "No Experience"
            )
        )
        aiExperienceStep.text = "How experienced are you with AI and machine learning?"
        steps.append(aiExperienceStep)

        // Time availability
        let timeAvailabilityStep = ORKQuestionStep(
            identifier: "timeAvailability",
            title: "Time Availability",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .singleChoice,
                textChoices: [
                    ORKTextChoice(text: "Less than 1 hour per week", value: "minimal"),
                    ORKTextChoice(text: "1-3 hours per week", value: "limited"),
                    ORKTextChoice(text: "3-5 hours per week", value: "moderate"),
                    ORKTextChoice(text: "5+ hours per week", value: "extensive")
                ]
            )
        )
        timeAvailabilityStep.text = "How much time can you dedicate to research per week?"
        steps.append(timeAvailabilityStep)

        // Study types preference
        let studyTypesStep = ORKQuestionStep(
            identifier: "preferredStudyTypes",
            title: "Preferred Study Types",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Surveys", value: "surveys"),
                    ORKTextChoice(text: "Sample Collection", value: "samples"),
                    ORKTextChoice(text: "Data Analysis", value: "analysis"),
                    ORKTextChoice(text: "Literature Review", value: "literature"),
                    ORKTextChoice(text: "Lab Work", value: "lab"),
                    ORKTextChoice(text: "Field Studies", value: "field")
                ]
            )
        )
        studyTypesStep.text = "What types of research activities interest you?"
        steps.append(studyTypesStep)

        // Motivation
        let motivationStep = ORKQuestionStep(
            identifier: "participationMotivation",
            title: "Participation Motivation",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300)
        )
        motivationStep.text = "What motivates you to participate in research?"
        motivationStep.isOptional = true
        steps.append(motivationStep)

        // Skills and expertise
        let skillsStep = ORKQuestionStep(
            identifier: "skills",
            title: "Skills and Expertise",
            answer: ORKAnswerFormat.textAnswerFormat(withMaximumLength: 300)
        )
        skillsStep.text = "What skills or expertise can you contribute?"
        skillsStep.isOptional = true
        steps.append(skillsStep)

        // Communication preferences
        let communicationStep = ORKQuestionStep(
            identifier: "communicationPreference",
            title: "Communication Preferences",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Email", value: "email"),
                    ORKTextChoice(text: "SMS", value: "sms"),
                    ORKTextChoice(text: "In-App Notifications", value: "notification"),
                    ORKTextChoice(text: "Push Notifications", value: "push")
                ]
            )
        )
        communicationStep.text = "How would you prefer to be contacted about studies?"
        steps.append(communicationStep)

        // Goals
        let goalsStep = ORKQuestionStep(
            identifier: "researchGoals",
            title: "Research Goals",
            answer: ORKAnswerFormat.choiceAnswerFormat(
                with: .multipleChoice,
                textChoices: [
                    ORKTextChoice(text: "Contribute to Science", value: "science"),
                    ORKTextChoice(text: "Learn New Skills", value: "learning"),
                    ORKTextChoice(text: "Earn Credit/Compensation", value: "compensation"),
                    ORKTextChoice(text: "Solve Real-World Problems", value: "problems"),
                    ORKTextChoice(text: "Networking", value: "networking")
                ]
            )
        )
        goalsStep.text = "What are your goals for participating in research?"
        steps.append(goalsStep)

        // Review step
        let reviewStep = ReviewStepFactory.createReviewStep(
            identifier: "onboarding_review",
            title: "Review Your Responses",
            text: "Please review your responses before completing onboarding"
        )
        steps.append(reviewStep)

        // Completion
        let completionStep = CompletionStepFactory.createCompletionStep(
            identifier: "onboarding_completion",
            title: "Onboarding Complete",
            text: "Welcome to AI4Science! You're all set to start participating in research."
        )
        steps.append(completionStep)

        return ORKOrderedTask(identifier: identifier, steps: steps)
    }
}

// MARK: - Models
struct OnboardingResponse: Codable, Sendable {
    let researchExperience: String
    let researchInterests: [String]
    let aiExperience: Int
    let timeAvailability: String
    let preferredStudyTypes: [String]
    let participationMotivation: String?
    let skills: String?
    let communicationPreference: [String]
    let researchGoals: [String]
}
