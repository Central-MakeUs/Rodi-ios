import Foundation

/// `GET /api/v1/courses/registration-form` 응답 계약.
struct CourseRegistrationFormResponseDTO: Decodable {
    let maxWaypoints: Int
    let sections: CourseRegistrationSectionsDTO
    let practiceType: CoursePracticeTypeFormDTO
    let inputs: CourseRegistrationInputsDTO
}

struct CourseRegistrationSectionsDTO: Decodable {
    let basicInfo: String
    let practiceCategory: String
    let practiceType: String
    let caution: String
    let description: String
}

struct CoursePracticeTypeFormDTO: Decodable {
    let maxSelect: Int
    let maxSelectExceededMessage: String
    let categories: [CoursePracticeCategoryDTO]
}

struct CoursePracticeCategoryDTO: Decodable {
    let code: String
    let label: String
    let order: Int
    let practiceTypes: [CoursePracticeTypeItemDTO]
}

struct CoursePracticeTypeItemDTO: Decodable {
    let code: String
    let label: String
    let order: Int
}

struct CourseRegistrationInputsDTO: Decodable {
    let caution: CourseInputSpecDTO
    let description: CourseInputSpecDTO
}

struct CourseInputSpecDTO: Decodable {
    let required: Bool
    let minLength: Int?
    let maxLength: Int
    let placeholder: String
}
