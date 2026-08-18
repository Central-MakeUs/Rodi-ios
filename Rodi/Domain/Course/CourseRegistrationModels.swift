import Foundation

struct CourseRegistrationForm: Equatable {
    let maxWaypoints: Int
    let sections: CourseRegistrationFormSections
    let practiceType: CourseRegistrationPracticeTypeForm
    let inputs: CourseRegistrationFormInputs
}

struct CourseRegistrationFormSections: Equatable {
    let basicInfo: String
    let practiceCategory: String
    let practiceType: String
    let caution: String
    let description: String
}

struct CourseRegistrationPracticeTypeForm: Equatable {
    let maxSelect: Int
    let maxSelectExceededMessage: String
    let categories: [CourseRegistrationPracticeCategory]
}

struct CourseRegistrationPracticeCategory: Equatable, Identifiable {
    let code: String
    let label: String
    let order: Int
    let practiceTypes: [CourseRegistrationPracticeType]

    var id: String { code }
}

struct CourseRegistrationPracticeType: Equatable, Identifiable {
    let code: String
    let label: String
    let order: Int

    var id: String { code }
}

struct CourseRegistrationFormInputs: Equatable {
    let caution: CourseRegistrationTextInputSpec
    let description: CourseRegistrationTextInputSpec
}

struct CourseRegistrationTextInputSpec: Equatable {
    let required: Bool
    let minLength: Int?
    let maxLength: Int
    let placeholder: String
}

struct CourseRegistrationSubmission: Equatable {
    let name: String
    let address: String
    let distanceMeters: Int
    let waypoints: [CourseRegistrationSubmissionWaypoint]
    let practiceTypes: [String]
    let description: String
    let caution: String
}

struct CourseRegistrationSubmissionWaypoint: Equatable {
    enum Kind: String, Equatable {
        case start = "START"
        case via = "VIA"
        case destination = "DESTINATION"
    }

    let kind: Kind
    let latitude: Double
    let longitude: Double
    let name: String
}

struct CourseRegistrationResult: Equatable {
    let courseID: Int
    let approvalStatus: String
}
