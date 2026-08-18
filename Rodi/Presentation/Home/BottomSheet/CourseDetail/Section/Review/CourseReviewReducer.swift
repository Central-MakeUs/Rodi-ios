import Foundation

struct CourseReviewReducer: Reducer {
    enum Route: Equatable {
        case preview
        case allReviews
        case report
    }

    enum SummaryResult {
        case success(PlaceReviewSummary)
        case failure(String)
    }

    enum PageResult {
        case success(PlaceReviewPage)
        case failure(String)
    }

    enum DeleteResult {
        case success
        case failure(String)
    }

    struct PageState: Equatable {
        var items: [PlaceReviewItem] = []
        var hasNext = false
        var nextCursor: String?
        var totalCount: Int?
        var isInitialLoading = false
        var isLoadingNextPage = false
        var errorMessage: String?
    }

    struct SummaryState: Equatable {
        var value: PlaceReviewSummary?
        var isLoading = false
        var errorMessage: String?
    }

    struct State: Equatable {
        var placeID: Int?
        var route: Route = .preview
        var reportReturnRoute: Route?
        var selectedLevel: ReviewLevelFilter = .current
        var summaries: [ReviewLevelFilter: SummaryState] = [:]
        var pages: [ReviewLevelFilter: PageState] = [:]
        var requestRevision = UUID()
        var reportedReviewIDs: Set<Int> = []
        var blockedMemberIDs: Set<Int> = []
        var report = CourseReviewReportReducer.State()
        var block = CourseReviewBlockReducer.State()
        var deleteTargetReviewID: Int?
        var isDeleting = false
        var deleteErrorMessage: String?
    }

    enum Action {
        case start(placeID: Int)
        case reset
        case allReviewsTapped
        case backTapped
        case levelSelected(ReviewLevelFilter)
        case retryTapped
        case reviewSubmissionRefreshRequested
        case nextPageRequested
        case summaryLoaded(SummaryResult, placeID: Int, level: ReviewLevelFilter, revision: UUID)
        case pageLoaded(PageResult, placeID: Int, level: ReviewLevelFilter, next: Bool, revision: UUID)
        case writingTapped
        case editRequested(reviewID: Int)
        case deleteRequested(reviewID: Int)
        case deleteCancelled
        case deleteConfirmed
        case deleteCompleted(DeleteResult, reviewID: Int)
        case reportRequested(reviewID: Int)
        case blockRequested(reviewID: Int)
        case report(CourseReviewReportReducer.Action)
        case block(CourseReviewBlockReducer.Action)
        case delegate(Delegate)
    }

    enum Delegate {
        case writingRequested
        case editingRequested(reviewID: Int)
        case requestAuthentication
        case showSnackbar(String)
    }

    private enum EffectID: Hashable { case loading, deletion }

    private let repository: ReviewRepository
    private let reportReducer: CourseReviewReportReducer
    private let blockReducer: CourseReviewBlockReducer

    init(repository: ReviewRepository, memberRepository: MemberRepository, hasActiveSession: @escaping () -> Bool) {
        self.repository = repository
        reportReducer = .init(repository: repository, hasActiveSession: hasActiveSession)
        blockReducer = .init(repository: memberRepository, hasActiveSession: hasActiveSession)
    }
}

// MARK: - Reduce
extension CourseReviewReducer {
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .start(let placeID):
            state = .init(placeID: placeID)
            return loadIfNeeded(state: &state, force: false)

        case .reset:
            state = .init()
            return .cancel(id: EffectID.loading)

        case .allReviewsTapped:
            guard state.route == .preview,
                  (state.summaries[state.selectedLevel]?.value?.totalReviewCount ?? 0) > 0
            else { return .none }
            state.route = .allReviews
            return loadIfNeeded(state: &state, force: false)

        case .backTapped:
            guard state.route == .allReviews else { return .none }
            state.route = .preview

        case .levelSelected(let level):
            guard state.route != .report, state.selectedLevel != level else { return .none }
            state.selectedLevel = level
            state.requestRevision = UUID()
            return loadIfNeeded(state: &state, force: false)

        case .retryTapped:
            guard state.route != .report else { return .none }
            state.summaries[state.selectedLevel] = .init()
            state.pages[state.selectedLevel] = nil
            return loadIfNeeded(state: &state, force: true)

        case .reviewSubmissionRefreshRequested:
            guard state.placeID != nil, state.route != .report else { return .none }
            return loadIfNeeded(state: &state, force: true)

        case .nextPageRequested:
            guard state.route == .allReviews,
                  let placeID = state.placeID,
                  var page = state.pages[state.selectedLevel],
                  page.hasNext,
                  !page.isLoadingNextPage,
                  let cursor = page.nextCursor
            else { return .none }
            page.isLoadingNextPage = true
            page.errorMessage = nil
            state.pages[state.selectedLevel] = page
            return loadPage(placeID: placeID, level: state.selectedLevel, cursor: cursor, revision: state.requestRevision)

        case let .summaryLoaded(result, placeID, level, revision):
            guard state.placeID == placeID, state.requestRevision == revision else { return .none }
            var summary = state.summaries[level] ?? .init()
            summary.isLoading = false
            switch result {
            case .success(let value): summary.value = value; summary.errorMessage = nil
            case .failure(let message): summary.errorMessage = message
            }
            state.summaries[level] = summary

        case let .pageLoaded(result, placeID, level, isNextPage, revision):
            guard state.placeID == placeID, state.requestRevision == revision else { return .none }
            var page = state.pages[level] ?? .init()
            page.isInitialLoading = false
            page.isLoadingNextPage = false
            switch result {
            case .success(let response):
                let visibleItems = response.items.filter { !state.reportedReviewIDs.contains($0.id) && !state.blockedMemberIDs.contains($0.memberID) }
                page.items = isNextPage ? page.items + visibleItems : visibleItems
                page.hasNext = response.hasNext
                page.nextCursor = response.nextCursor
                page.totalCount = response.totalCount
                page.errorMessage = nil
            case .failure(let message): page.errorMessage = message
            }
            state.pages[level] = page

        case .writingTapped:
            return .send(.delegate(.writingRequested))

        case .editRequested(let reviewID):
            guard state.route == .preview || state.route == .allReviews,
                  let review = review(id: reviewID, state: state),
                  review.isMine
            else { return .none }
            return .send(.delegate(.editingRequested(reviewID: reviewID)))

        case .deleteRequested(let reviewID):
            guard !state.isDeleting,
                  state.route == .preview || state.route == .allReviews,
                  let review = review(id: reviewID, state: state),
                  review.isMine
            else { return .none }
            state.deleteTargetReviewID = reviewID
            state.deleteErrorMessage = nil

        case .deleteCancelled:
            guard !state.isDeleting else { return .none }
            state.deleteTargetReviewID = nil
            state.deleteErrorMessage = nil

        case .deleteConfirmed:
            guard let reviewID = state.deleteTargetReviewID, !state.isDeleting else { return .none }
            state.isDeleting = true
            state.deleteErrorMessage = nil
            return deleteEffect(reviewID: reviewID)

        case .deleteCompleted(let result, let reviewID):
            guard state.deleteTargetReviewID == reviewID, state.isDeleting else { return .none }
            state.isDeleting = false
            switch result {
            case .success:
                let shouldDismissAllReviews = shouldDismissAllReviewsAfterDeletion(state: state)
                state.deleteTargetReviewID = nil
                state.deleteErrorMessage = nil
                if shouldDismissAllReviews {
                    state.route = .preview
                }
                return .run { send in
                    await send(.retryTapped)
                    await send(.delegate(.showSnackbar("후기를 삭제했습니다.")))
                }
            case .failure(let message):
                state.deleteErrorMessage = message
            }

        case .reportRequested(let reviewID):
            guard state.route == .preview || state.route == .allReviews,
                  let review = review(id: reviewID, state: state)
            else { return .none }
            guard !review.isMine else {
                return .send(.delegate(.showSnackbar("내가 쓴 후기는 신고할 수 없습니다.")))
            }
            state.reportReturnRoute = state.route
            state.route = .report
            return reportReducer.reduce(&state.report, with: .start(reviewID: reviewID)).map(Action.report)

        case .blockRequested(let reviewID):
            guard let review = review(id: reviewID, state: state) else { return .none }
            guard !review.isMine else {
                return .send(.delegate(.showSnackbar("내가 쓴 후기는 차단할 수 없습니다.")))
            }
            return blockReducer.reduce(&state.block, with: .request(memberID: review.memberID)).map(Action.block)

        case .report(let childAction):
            if case .delegate(let delegate) = childAction { return reduceReportDelegate(delegate, state: &state) }
            return reportReducer.reduce(&state.report, with: childAction).map(Action.report)

        case .block(let childAction):
            if case .delegate(let delegate) = childAction { return reduceBlockDelegate(delegate, state: &state) }
            return blockReducer.reduce(&state.block, with: childAction).map(Action.block)

        case .delegate:
            return .none
        }
        return .none
    }
}

// MARK: - Child Delegate
private extension CourseReviewReducer {
    func reduceReportDelegate(_ delegate: CourseReviewReportReducer.Delegate, state: inout State) -> Effect<Action> {
        switch delegate {
        case .submitted(let reviewID):
            state.reportedReviewIDs.insert(reviewID)
            removeReview(id: reviewID, state: &state)
            state.route = state.reportReturnRoute ?? .preview
            state.reportReturnRoute = nil
            state.report = .init()
            return loadIfNeeded(state: &state, force: true)
        case .dismissed:
            state.route = state.reportReturnRoute ?? .preview
            state.reportReturnRoute = nil
            state.report = .init()
        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))
        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
        return .none
    }

    func reduceBlockDelegate(_ delegate: CourseReviewBlockReducer.Delegate, state: inout State) -> Effect<Action> {
        switch delegate {
        case .blocked(let memberID):
            state.blockedMemberIDs.insert(memberID)
            removeMember(id: memberID, state: &state)
            state.block = .init()
            return .send(.delegate(.showSnackbar("사용자를 차단했어요.")))
        case .requestAuthentication:
            return .send(.delegate(.requestAuthentication))
        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }
}

// MARK: - Effect
private extension CourseReviewReducer {
    func shouldDismissAllReviewsAfterDeletion(state: State) -> Bool {
        guard state.route == .allReviews,
              let page = state.pages[state.selectedLevel]
        else {
            return false
        }

        if let totalCount = page.totalCount {
            return totalCount <= 1
        }

        return page.items.count <= 1 && !page.hasNext
    }

    func loadIfNeeded(state: inout State, force: Bool) -> Effect<Action> {
        guard let placeID = state.placeID else { return .none }
        let level = state.selectedLevel
        let needsSummary = force || state.summaries[level]?.value == nil
        let needsPage = force || state.pages[level] == nil
        guard needsSummary || needsPage else { return .none }

        let revision = UUID()
        state.requestRevision = revision
        updateLoadingState(level: level, needsSummary: needsSummary, needsPage: needsPage, force: force, state: &state)
        let repository = repository
        return .run { send in
            if needsSummary {
                do { await send(.summaryLoaded(.success(try await repository.fetchSummary(placeID: placeID, level: level)), placeID: placeID, level: level, revision: revision)) }
                catch { await send(.summaryLoaded(.failure("후기 요약을 불러오지 못했어요."), placeID: placeID, level: level, revision: revision)) }
            }
            if needsPage {
                do { await send(.pageLoaded(.success(try await repository.fetchReviews(placeID: placeID, query: .init(level: level))), placeID: placeID, level: level, next: false, revision: revision)) }
                catch { await send(.pageLoaded(.failure("후기를 불러오지 못했어요."), placeID: placeID, level: level, next: false, revision: revision)) }
            }
        }
        .cancelTask(id: EffectID.loading)
    }

    func loadPage(placeID: Int, level: ReviewLevelFilter, cursor: String, revision: UUID) -> Effect<Action> {
        let repository = repository
        return .run { send in
            do { await send(.pageLoaded(.success(try await repository.fetchReviews(placeID: placeID, query: .init(level: level, cursor: cursor))), placeID: placeID, level: level, next: true, revision: revision)) }
            catch is CancellationError { }
            catch { await send(.pageLoaded(.failure("후기를 더 불러오지 못했어요."), placeID: placeID, level: level, next: true, revision: revision)) }
        }
        .cancelTask(id: EffectID.loading)
    }

    func deleteEffect(reviewID: Int) -> Effect<Action> {
        let repository = repository
        return .run { send in
            do {
                try await repository.delete(reviewID: reviewID)
                await send(.deleteCompleted(.success, reviewID: reviewID))
            } catch let error as NetworkError {
                await send(.deleteCompleted(.failure(deleteMessage(for: error)), reviewID: reviewID))
            } catch {
                await send(.deleteCompleted(.failure("후기를 삭제하지 못했어요. 다시 시도해주세요."), reviewID: reviewID))
            }
        }
        .cancelTask(id: EffectID.deletion)
    }

    func deleteMessage(for error: NetworkError) -> String {
        if case .networkUnavailable = error {
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        }
        return "후기를 삭제하지 못했어요. 다시 시도해주세요."
    }
}

// MARK: - State
private extension CourseReviewReducer {
    func updateLoadingState(level: ReviewLevelFilter, needsSummary: Bool, needsPage: Bool, force: Bool, state: inout State) {
        if needsSummary {
            var summary = state.summaries[level] ?? .init()
            summary.isLoading = true
            summary.errorMessage = nil
            state.summaries[level] = summary
        }
        if needsPage {
            var page = state.pages[level] ?? .init()
            page.isInitialLoading = true
            page.isLoadingNextPage = false
            page.errorMessage = nil
            if force { page.items = []; page.hasNext = false; page.nextCursor = nil; page.totalCount = nil }
            state.pages[level] = page
        }
    }

    func review(id: Int, state: State) -> PlaceReviewItem? {
        state.pages.values.lazy.flatMap(\.items).first { $0.id == id }
    }

    func removeReview(id: Int, state: inout State) {
        for key in state.pages.keys { state.pages[key]?.items.removeAll { $0.id == id } }
    }

    func removeMember(id: Int, state: inout State) {
        for key in state.pages.keys { state.pages[key]?.items.removeAll { $0.memberID == id } }
    }
}
