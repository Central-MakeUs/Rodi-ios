import Foundation

enum MyCourseApprovalStatus: String, CaseIterable, Equatable {
    case pending = "PENDING"
    case approved = "APPROVED"
    case rejected = "REJECTED"

    var title: String {
        switch self {
        case .pending: "검토중"
        case .approved: "승인"
        case .rejected: "반려"
        }
    }
}

struct MyCourseItem: Equatable, Identifiable {
    let id: Int64
    let name: String
    let approvalStatus: MyCourseApprovalStatus
    /// 서버의 LocalDateTime 원문. 시간대가 없는 ISO 문자열도 보존해 표시한다.
    let createdAt: String
}

struct MyCoursePage: Equatable {
    let items: [MyCourseItem]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct MyCourseQuery: Equatable {
    let status: MyCourseApprovalStatus?
    let size: Int
    let cursor: String?

    init(status: MyCourseApprovalStatus? = nil, size: Int = 20, cursor: String? = nil) {
        self.status = status
        self.size = size
        self.cursor = cursor
    }
}
