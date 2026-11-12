import Alamofire
import Foundation

enum CourseAPI: TargetType {
    case registrationForm
    case register(CourseRegisterRequestDTO)
    case myCourses(MyCourseListQueryDTO)
    case deleteMyCourse(courseID: Int64)
    case reportForm
    case report(courseID: Int64, request: CourseReportRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .registrationForm, .myCourses, .reportForm: .get
        case .register, .report: .post
        case .deleteMyCourse: .delete
        }
    }

    var path: String {
        switch self {
        case .registrationForm: "/api/v1/courses/registration-form"
        case .register: "/api/v1/courses"
        case .myCourses: "/api/v1/members/me/courses"
        case .deleteMyCourse(let courseID): "/api/v1/courses/\(courseID)"
        case .reportForm: "/api/v1/courses/report-form"
        case .report(let courseID, _): "/api/v1/courses/\(courseID)/report"
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
        case .registrationForm, .myCourses, .deleteMyCourse, .reportForm: nil
        case .register(let request): requestToBody(request)
        case .report(_, let request): requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .registrationForm, .myCourses, .deleteMyCourse, .reportForm: .url
        case .register, .report: .json
        }
    }

    // Swagger 표기와 달리 실제 registration-form 응답은 AUTH_401을 반환한다.
    var requiresAuthentication: Bool { true }
}
