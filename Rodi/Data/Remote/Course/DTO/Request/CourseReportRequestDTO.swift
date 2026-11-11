import Foundation

struct CourseReportRequestDTO: Encodable {
    let courseIssues: [String]
    let detail: String?
}
