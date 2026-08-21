import Alamofire
import Foundation

enum ReviewAPI: TargetType {
    case create(placeID: Int, request: ReviewRequestDTO)
    case detail(reviewID: Int)
    case update(reviewID: Int, request: ReviewRequestDTO)
    case summary(placeID: Int, query: ReviewSummaryQueryDTO)
    case list(placeID: Int, query: PlaceReviewListQueryDTO)
    case myReviews(query: MyReviewListQueryDTO)
    case delete(reviewID: Int)
    case reportForm
    case report(reviewID: Int, request: ReviewReportRequestDTO)

    var method: HTTPMethod {
        switch self {
        case .create, .report: .post
        case .update: .put
        case .delete: .delete
        case .summary, .list, .myReviews, .reportForm, .detail: .get
        }
    }

    var path: String {
        switch self {
        case .create(let placeID, _): "/api/v1/places/\(placeID)/reviews"
        case .detail(let reviewID), .update(let reviewID, _): "/api/v1/reviews/\(reviewID)"
        case .summary(let placeID, _): "/api/v1/places/\(placeID)/reviews/summary"
        case .list(let placeID, _): "/api/v1/places/\(placeID)/reviews"
        case .myReviews: "/api/v1/members/me/reviews"
        case .delete(let reviewID): "/api/v1/reviews/\(reviewID)"
        case .reportForm: "/api/v1/reviews/report-form"
        case .report(let reviewID, _): "/api/v1/reviews/\(reviewID)/report"
        }
    }
    var optionalHeaders: HTTPHeaders? { nil }

    var parameters: Parameters? {
        switch self {
        case .create:
            return nil

        case .summary(_, let query):
            guard let level = query.level else { return nil }
            return ["level": level]

        case .list(_, let query):
            var parameters: Parameters = ["size": query.size]
            if let level = query.level {
                parameters["level"] = level
            }
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters

        case .myReviews(let query):
            var parameters: Parameters = ["size": query.size]
            if let cursor = query.cursor, !cursor.isEmpty {
                parameters["cursor"] = cursor
            }
            return parameters

        case .detail, .update, .delete, .reportForm, .report:
            return nil
        }
    }

    var body: Data? {
        switch self {
        case .create(_, let request): requestToBody(request)
        case .update(_, let request): requestToBody(request)
        case .report(_, let request): requestToBody(request)
        case .summary, .list, .myReviews, .detail, .delete, .reportForm: nil
        }
    }

    var encodingType: EncodingType {
        switch self {
        case .create, .update, .report: .json
        case .summary, .list, .myReviews, .detail, .delete, .reportForm: .url
        }
    }

    var requiresAuthentication: Bool { true }
}
