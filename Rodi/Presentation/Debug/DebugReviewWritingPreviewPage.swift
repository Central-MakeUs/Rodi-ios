#if DEBUG
import SwiftUI

struct DebugReviewWritingPreviewPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = Store(state: ReviewWritingReducer.State(), reducer: PreviewReducer())

    var body: some View {
        ReviewView(state: .init(route: .writing, writing: store.state)) { action in
            if case .writing(let action) = action { store.send(action) }
        }
        .onAppear {
            guard store.state.page == .hidden else { return }
            store.send(.start(.init(placeID: 1, placeName: "테스트 코스")))
        }
        .onChange(of: store.state.page) { page in
            if page == .hidden { dismiss() }
        }
    }

    private struct PreviewReducer: Reducer {
        private let writing = ReviewWritingReducer(service: DebugReviewWritingService(), tracksAnalytics: false)

        func reduce(_ state: inout ReviewWritingReducer.State, with action: ReviewWritingReducer.Action) -> Effect<ReviewWritingReducer.Action> {
            switch action {
            case .delegate(.finished):
                return writing.reduce(&state, with: .reset)
            case .delegate(.completionRefreshRequested(_, let flowID)):
                return .send(.completionRefreshFinished(flowID: flowID))
            default:
                return writing.reduce(&state, with: action)
            }
        }
    }
}

struct DebugReviewWritingService: ReviewWritingServicing {
    let usesServerForm = true

    func fetchWritingForm(placeID: Int) async throws -> ReviewWritingForm { Self.form }
    func fetchReviewDetail(reviewID: Int) async throws -> ReviewDetail { throw NetworkError.decodingFail }
    func createReview(placeID: Int, submission: PlaceReviewSubmission) async throws {}
    func updateReview(reviewID: Int, submission: PlaceReviewSubmission) async throws {}

    static var form: ReviewWritingForm {
        .init(title: "후기 남기기", placeName: "테스트 코스", firstStepTitle: "테스트 코스의\n연습은 어땠나요?", questions: [
            .isRecommended: question("이 코스를 다른 초보 운전자에게 추천하시겠어요?", options: [
                option("false", "별로에요"), option("true", "추천해요")
            ]),
            .difficulty: question("난이도", when: [true], options: ReviewDifficulty.allCases.map { option($0.rawValue, $0.title) }),
            .congestion: question("혼잡도", when: [true], options: ReviewCongestion.allCases.map { option($0.rawValue, $0.title) }),
            .caution: question("주의사항", required: false, placeholder: "주의사항을 작성해주세요.", when: [true]),
            .courseIssues: question("해당 코스에 어떤 문제가 있나요?", when: [false], options: [
                option("VEHICLE_RESTRICTED", "차량 진입이 제한된 장소예요"),
                option("ROAD_INFO_MISMATCH", "도로 정보가 실제와 달라요"),
                option("CONSTRUCTION", "공사·통제 중이에요"),
                option("NOT_FOR_PRACTICE", "연습 코스로 적합하지 않아요"),
                .init(code: "OTHER", label: "기타", requiresTextInput: true, textInputPlaceholder: "이유를 작성해주세요.", textInputMaxLength: 30)
            ]),
            .practiceMethod: question("연습 방법", options: ReviewPracticeMethod.allCases.map { option($0.rawValue, $0.title) }),
            .content: question("후기 작성", required: false, placeholder: "자유롭게 후기를 작성해주세요.", maxLength: 150)
        ])
    }

    private static func question(
        _ title: String, required: Bool = true, placeholder: String? = nil,
        maxLength: Int? = nil, when: Set<Bool>? = nil, options: [ReviewWritingForm.Option] = []
    ) -> ReviewWritingForm.Question {
        .init(title: title, required: required, placeholder: placeholder, maxLength: maxLength, recommendations: when, options: options)
    }

    private static func option(_ code: String, _ label: String) -> ReviewWritingForm.Option {
        .init(code: code, label: label, requiresTextInput: false, textInputPlaceholder: nil, textInputMaxLength: nil)
    }
}
#endif
