import Foundation

enum ReviewLevel: String, CaseIterable, Equatable, Hashable, Identifiable {
    case seed = "SEED"
    case rookie = "ROOKIE"
    case owner = "OWNER"
    case explorer = "EXPLORER"
    case navigator = "NAVIGATOR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seed: "Seed"
        case .rookie: "Rookie"
        case .owner: "Owner"
        case .explorer: "Explorer"
        case .navigator: "Navigator"
        }
    }
}

enum ReviewLevelFilter: Equatable, Hashable {
    case current
    case level(ReviewLevel)
    case all

    var queryValue: String? {
        switch self {
        case .current: nil
        case .level(let level): level.rawValue
        case .all: "ALL"
        }
    }

    var displayName: String {
        switch self {
        case .current: "내 레벨"
        case .level(let level): level.displayName
        case .all: "전체"
        }
    }
}

enum ReviewDifficulty: String, CaseIterable, Equatable, Hashable {
    case veryEasy = "VERY_EASY"
    case easy = "EASY"
    case normal = "NORMAL"
    case hard = "HARD"
    case veryHard = "VERY_HARD"

    var title: String {
        switch self {
        case .veryEasy: "매우 쉬움"
        case .easy: "쉬움"
        case .normal: "보통"
        case .hard: "어려움"
        case .veryHard: "매우 어려움"
        }
    }
}

enum ReviewCongestion: String, CaseIterable, Equatable, Hashable {
    case quiet = "QUIET"
    case normal = "NORMAL"
    case crowded = "CROWDED"

    var title: String {
        switch self {
        case .quiet: "한산해요"
        case .normal: "보통이에요"
        case .crowded: "복잡해요"
        }
    }
}

enum ReviewPracticeMethod: String, CaseIterable, Equatable, Hashable {
    case solo = "SOLO"
    case accompanied = "ACCOMPANIED"

    var title: String {
        switch self {
        case .solo: "혼자 연습"
        case .accompanied: "동승자와 연습"
        }
    }
}

struct PlaceReviewSubmission: Equatable {
    let isRecommended: Bool
    let difficulty: ReviewDifficulty
    let congestion: ReviewCongestion
    let practiceMethod: ReviewPracticeMethod
    let content: String?
    let caution: String?
}

struct ReviewDetail: Equatable {
    let reviewID: Int
    let placeID: Int
    let placeName: String
    let isRecommended: Bool
    let difficulty: ReviewDifficulty
    let congestion: ReviewCongestion
    let practiceMethod: ReviewPracticeMethod
    let content: String?
    let caution: String?
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: String
}

struct ReviewReportForm: Equatable {
    let title: String
    let description: String?
    let options: [ReviewReportOption]
}

struct ReviewReportOption: Equatable, Identifiable {
    let code: String
    let label: String
    let order: Int
    let requiresTextInput: Bool
    let textInputPlaceholder: String?
    let textInputMaxLength: Int?

    var id: String { code }
}

struct ReviewReportSubmission: Equatable {
    let reasonCode: String
    let detail: String?
}

struct PlaceReviewSummary: Equatable {
    let level: ReviewLevel?
    let levelReviewCount: Int
    let totalReviewCount: Int
    let topDifficulty: ReviewDifficulty?
    let topDifficultyCount: Int
    let recommendCount: Int
    let notRecommendCount: Int
    let difficultyCounts: [ReviewDifficulty: Int]
    let levelCounts: [ReviewLevel: Int]

    var hasOtherLevelReviews: Bool {
        totalReviewCount > levelReviewCount
    }
}

struct PlaceReviewItem: Equatable, Identifiable {
    let id: Int
    let memberID: Int
    let nickname: String?
    let practiceMethod: ReviewPracticeMethod
    let content: String
    let isMine: Bool
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: String

    var displayNickname: String {
        nickname?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "탈퇴한 회원"
    }

    var practiceMethodDisplayName: String {
        switch practiceMethod {
        case .solo: "혼자 왔어요"
        case .accompanied: "동행했어요"
        }
    }
}

struct PlaceReviewPage: Equatable {
    let items: [PlaceReviewItem]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct PlaceReviewQuery: Equatable {
    let level: ReviewLevelFilter
    let size: Int
    let cursor: String?

    init(level: ReviewLevelFilter, size: Int = 10, cursor: String? = nil) {
        self.level = level
        self.size = size
        self.cursor = cursor
    }
}

struct MyReviewItem: Equatable, Identifiable {
    let id: Int
    let placeID: Int
    let placeName: String
    let content: String
    let isEditable: Bool
    let isHidden: Bool
    let isVerifiedVisit: Bool
    let createdAt: Date
}

struct MyReviewPage: Equatable {
    let items: [MyReviewItem]
    let hasNext: Bool
    let nextCursor: String?
    let totalCount: Int?
}

struct MyReviewQuery: Equatable {
    let size: Int
    let cursor: String?

    init(size: Int = 10, cursor: String? = nil) {
        self.size = size
        self.cursor = cursor
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
