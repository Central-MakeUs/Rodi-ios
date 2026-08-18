import Alamofire
import Foundation

enum CourseAPI: TargetType {
    case registrationForm
    case register(CourseRegisterRequestDTO)
    case myCourses(MyCourseListQueryDTO)
    case deleteMyCourse(courseID: Int64)

    var method: HTTPMethod {
        switch self {
        case .registrationForm: .get
        case .register: .post
        case .myCourses: .get
        case .deleteMyCourse: .delete
        }
    }

    var path: String {
        switch self {
        case .registrationForm: "/api/v1/courses/registration-form"
        case .register: "/api/v1/courses"
        case .myCourses: "/api/v1/members/me/courses"
        case .deleteMyCourse(let courseID): "/api/v1/courses/\(courseID)"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        switch self {
        case .myCourses(let query):
            var parameters: Parameters = ["size": query.size ?? 20]
            if let status = query.status {
                parameters["status"] = status
            }
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters
        default:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .registrationForm: nil
        case .register(let request): requestToBody(request)
        case .myCourses, .deleteMyCourse: nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .registrationForm, .myCourses, .deleteMyCourse: .url
        case .register: .json
        }
    }

    // Swagger 표기와 달리 실제 registration-form 응답은 AUTH_401을 반환한다.
    var requiresAuthentication: Bool { true }
}
