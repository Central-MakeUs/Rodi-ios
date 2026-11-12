struct CourseReportForm: Equatable {
    struct Option: Equatable, Identifiable {
        let code: String
        let label: String
        let textInputPlaceholder: String?
        let textInputMaxLength: Int?

        var id: String { code }
        var requiresTextInput: Bool { code == "OTHER" }
    }

    let title: String
    let description: String?
    let options: [Option]
}

struct CourseReportSubmission: Equatable {
    let issueCodes: [String]
    let detail: String?
}
