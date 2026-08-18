import Alamofire
import Foundation

enum PracticeAPI: TargetType {
    case register(placeID: Int)
    case recordVisit(practiceID: Int, request: PracticeVisitRequestDTO)
    case myPractices(query: MyPracticeQuery)
    case skipReasonForm
    case submitSkipReason(practiceID: Int, request: PracticeSkipReasonRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .myPractices, .skipReasonForm:
            .get
        case .register, .recordVisit, .submitSkipReason:
            .post
        }
    }

    var path: String {
        switch self {
        case .register(let placeID): "/api/v1/places/\(placeID)/practices"
        case .recordVisit(let practiceID, _): "/api/v1/practices/\(practiceID)/visits"
        case .myPractices: "/api/v1/members/me/practices"
        case .skipReasonForm: "/api/v1/practices/skip-reason-form"
        case .submitSkipReason(let practiceID, _): "/api/v1/practices/\(practiceID)/skip-reason"
        }
    }

    var optionalHeaders: HTTPHeaders? { nil }
    var parameters: Parameters? {
        switch self {
        case .myPractices(let query):
            var parameters: Parameters = ["size": query.size]
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters

        case .register, .recordVisit, .skipReasonForm, .submitSkipReason:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .register:
            nil
        case .recordVisit(_, let request):
            requestToBody(request)
        case .skipReasonForm:
            nil
        case .myPractices:
            nil
        case .submitSkipReason(_, let request):
            requestToBody(request)
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .myPractices, .skipReasonForm:
            .url
        case .register, .recordVisit, .submitSkipReason:
            .json
        }
    }
    var requiresAuthentication: Bool { true }
}
