import Foundation

struct ReviewReducer: Reducer {
    struct State {
        var route: ReviewFlowRoute = .hidden
        var prompt = ReviewPromptReducer.State()
        var writing = ReviewWritingReducer.State()
        var skipReason = ReviewSkipReasonReducer.State()

        var isPresented: Bool {
            route != .hidden
        }
    }

    enum Action {
        case debugPromptRequested
        case promptRequested(
            placeID: Int,
            placeName: String,
            allowsSkipReason: Bool = true,
            allowsReviewWriting: Bool = true,
            visitedSnackbarMessage: String? = nil
        )
        case directWritingRequested(ReviewWriteRequest)
        case editingRequested(reviewID: Int)
        case reset
        case prompt(ReviewPromptReducer.Action)
        case writing(ReviewWritingReducer.Action)
        case skipReason(ReviewSkipReasonReducer.Action)
        case delegate(Delegate)
    }

    enum Delegate {
        case finished
        case completionRefreshRequested(ReviewWriteRequest, flowID: UUID)
        case editingFailed(String)
        case showSnackbar(String)
        case visitedWithoutReview(String)
    }

    private let promptReducer: ReviewPromptReducer
    private let writingReducer: ReviewWritingReducer
    private let skipReasonReducer: ReviewSkipReasonReducer

    init(
        promptService: any ReviewPromptServicing,
        writingService: any ReviewWritingServicing,
        skipReasonService: any ReviewSkipReasonServicing
    ) {
        promptReducer = .init(service: promptService)
        writingReducer = .init(service: writingService)
        skipReasonReducer = .init(service: skipReasonService)
    }
}

// MARK: - Reduce
extension ReviewReducer {

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .debugPromptRequested:
            #if DEBUG
            guard state.route == .hidden else { return .none }
            return startPrompt(
                state: &state,
                placeID: 120,
                placeName: "북악스카이웨이 드라이브"
            )
            #else
            return .none
            #endif

        case let .promptRequested(placeID, placeName, allowsSkipReason, allowsReviewWriting, visitedSnackbarMessage):
            guard state.route == .hidden else { return .none }
            return startPrompt(
                state: &state,
                placeID: placeID,
                placeName: placeName,
                allowsSkipReason: allowsSkipReason,
                allowsReviewWriting: allowsReviewWriting,
                visitedSnackbarMessage: visitedSnackbarMessage
            )

        case .directWritingRequested(let request):
            guard state.route == .hidden else { return .none }
            resetChildren(state: &state)
            state.route = .writing
            return writingReducer
                .reduce(&state.writing, with: .start(request))
                .map(Action.writing)

        case .editingRequested(let reviewID):
            guard state.route == .hidden else { return .none }
            resetChildren(state: &state)
            state.route = .writing
            return writingReducer
                .reduce(&state.writing, with: .editStarted(reviewID: reviewID))
                .map(Action.writing)

        case .reset:
            resetChildren(state: &state)
            state.route = .hidden
            return .run { send in
                await send(.prompt(.reset))
                await send(.writing(.reset))
                await send(.skipReason(.reset))
            }

        case .prompt(let childAction):
            if case .delegate(let delegate) = childAction {
                return reducePromptDelegate(delegate, state: &state)
            }
            return promptReducer
                .reduce(&state.prompt, with: childAction)
                .map(Action.prompt)

        case .writing(let childAction):
            if case .delegate(let delegate) = childAction {
                return reduceWritingDelegate(delegate, state: &state)
            }
            return writingReducer
                .reduce(&state.writing, with: childAction)
                .map(Action.writing)

        case .skipReason(let childAction):
            if case .delegate(let delegate) = childAction {
                return reduceSkipReasonDelegate(delegate, state: &state)
            }
            return skipReasonReducer
                .reduce(&state.skipReason, with: childAction)
                .map(Action.skipReason)

        case .delegate:
            return .none
        }
    }
}

// MARK: - Child Delegate
private extension ReviewReducer {

    func reducePromptDelegate(
        _ delegate: ReviewPromptReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .writingRequested(let request):
            guard state.route == .prompt else { return .none }
            state.prompt = .init()
            state.route = .writing
            return writingReducer
                .reduce(&state.writing, with: .start(request))
                .map(Action.writing)

        case .skipReasonRequested(let target):
            guard state.route == .prompt else { return .none }
            state.prompt = .init()
            state.route = .skipReason
            return skipReasonReducer
                .reduce(&state.skipReason, with: .start(target))
                .map(Action.skipReason)

        case .dismissed:
            guard state.route == .prompt else { return .none }
            finish(state: &state)
            return .send(.delegate(.finished))

        case .preparationFailed(let message):
            guard state.route == .prompt else { return .none }
            finish(state: &state)
            return .send(.delegate(.showSnackbar(message)))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))

        case .visitedWithoutReview(let message):
            guard state.route == .prompt else { return .none }
            finish(state: &state)
            return .send(.delegate(.visitedWithoutReview(message)))
        }
    }

    func reduceWritingDelegate(
        _ delegate: ReviewWritingReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .finished:
            guard state.route == .writing else { return .none }
            finish(state: &state)
            return .send(.delegate(.finished))

        case .completionRefreshRequested(let target, let flowID):
            guard state.route == .writing else { return .none }
            return .send(.delegate(.completionRefreshRequested(target, flowID: flowID)))

        case .editingFailed(let message):
            guard state.route == .writing else { return .none }
            finish(state: &state)
            return .send(.delegate(.editingFailed(message)))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }

    func reduceSkipReasonDelegate(
        _ delegate: ReviewSkipReasonReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .finished:
            guard state.route == .skipReason else { return .none }
            finish(state: &state)
            return .send(.delegate(.finished))

        case .showSnackbar(let message):
            return .send(.delegate(.showSnackbar(message)))
        }
    }
}

// MARK: - State
private extension ReviewReducer {

    func startPrompt(
        state: inout State,
        placeID: Int,
        placeName: String,
        allowsSkipReason: Bool = true,
        allowsReviewWriting: Bool = true,
        visitedSnackbarMessage: String? = nil
    ) -> Effect<Action> {
        resetChildren(state: &state)
        state.route = .prompt
        return promptReducer
            .reduce(
                &state.prompt,
                with: .start(
                    placeID: placeID,
                    placeName: placeName,
                    allowsSkipReason: allowsSkipReason,
                    allowsReviewWriting: allowsReviewWriting,
                    visitedSnackbarMessage: visitedSnackbarMessage
                )
            )
            .map(Action.prompt)
    }

    func finish(state: inout State) {
        resetChildren(state: &state)
        state.route = .hidden
    }

    func resetChildren(state: inout State) {
        state.prompt = .init()
        state.writing = .init()
        state.skipReason = .init()
    }
}
