import Foundation

nonisolated enum CourseMapper {
    static func registrationForm(
        from dto: CourseRegistrationFormResponseDTO
    ) -> CourseRegistrationForm {
        .init(
            maxWaypoints: dto.maxWaypoints,
            sections: .init(
                basicInfo: dto.sections.basicInfo,
                practiceCategory: dto.sections.practiceCategory,
                practiceType: dto.sections.practiceType,
                caution: dto.sections.caution,
                description: dto.sections.description
            ),
            practiceType: .init(
                maxSelect: dto.practiceType.maxSelect,
                maxSelectExceededMessage: dto.practiceType.maxSelectExceededMessage,
                categories: dto.practiceType.categories
                    .sorted { $0.order < $1.order }
                    .map(practiceCategory(from:))
            ),
            inputs: .init(
                caution: textInput(from: dto.inputs.caution),
                description: textInput(from: dto.inputs.description)
            )
        )
    }

    static func registrationResult(
        from dto: CourseRegisterResponseDTO
    ) throws(NetworkError) -> CourseRegistrationResult {
        guard let courseID = Int(exactly: dto.courseId) else {
            throw .decodingFail
        }

        return .init(courseID: courseID, approvalStatus: dto.approvalStatus)
    }

    static func myCoursePage(
        from dto: MyCourseCursorPageResponseDTO
    ) throws(NetworkError) -> MyCoursePage {
        .init(
            items: try dto.items.map(myCourseItem(from:)),
            hasNext: dto.hasNext,
            nextCursor: dto.nextCursor,
            totalCount: try dto.totalCount.map(int(from:))
        )
    }

    private static func practiceCategory(
        from dto: CoursePracticeCategoryDTO
    ) -> CourseRegistrationPracticeCategory {
        .init(
            code: dto.code,
            label: dto.label,
            order: dto.order,
            practiceTypes: dto.practiceTypes
                .sorted { $0.order < $1.order }
                .map {
                    .init(code: $0.code, label: $0.label, order: $0.order)
                }
        )
    }

    private static func textInput(
        from dto: CourseInputSpecDTO
    ) -> CourseRegistrationTextInputSpec {
        .init(
            required: dto.required,
            minLength: dto.minLength,
            maxLength: dto.maxLength,
            placeholder: dto.placeholder
        )
    }

    private static func myCourseItem(
        from dto: MyCourseItemResponseDTO
    ) throws(NetworkError) -> MyCourseItem {
        guard let approvalStatus = MyCourseApprovalStatus(rawValue: dto.approvalStatus) else {
            throw .decodingFail
        }

        return .init(
            id: dto.courseId,
            name: dto.name,
            approvalStatus: approvalStatus,
            createdAt: dto.createdAt
        )
    }

    private static func int(from value: Int64) throws(NetworkError) -> Int {
        guard let value = Int(exactly: value) else {
            throw .decodingFail
        }
        return value
    }
}

nonisolated extension CourseRegisterRequestDTO {
    init(_ submission: CourseRegistrationSubmission) {
        self.init(
            name: submission.name,
            address: submission.address,
            distanceMeters: submission.distanceMeters,
            waypoints: submission.waypoints.map {
                .init(type: $0.kind.rawValue, lat: $0.latitude, lng: $0.longitude, name: $0.name)
            },
            practiceTypes: submission.practiceTypes,
            description: submission.description,
            caution: submission.caution
        )
    }
}

nonisolated extension MyCourseListQueryDTO {
    init(_ query: MyCourseQuery) {
        self.init(
            status: query.status?.rawValue,
            size: query.size,
            cursor: query.cursor
        )
    }
}
