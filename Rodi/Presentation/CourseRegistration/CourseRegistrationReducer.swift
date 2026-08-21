import Foundation

@MainActor
struct CourseRegistrationReducer: Reducer {
    struct State: Equatable {
        enum Route: Equatable {
            case tutorial
            case registration
            case registrationSearch(CourseRegistrationInputTarget)
            case pinEditing
            case pinEditSearch
            case details
        }

        var route: Route
        var tutorial = CourseRegistrationTutorialReducer.State()
        var mapSelection: CourseRegistrationMapSelectionReducer.State
        var placeSearch = CourseRegistrationPlaceSearchReducer.State()
        var errorMessage: String?
        var errorRevision = 0
        var tutorialCompletionRevision = 0
        var pinEditing: CourseRegistrationPinEditingReducer.State?
        var details = CourseRegistrationDetailsReducer.State()
        var isRegistrationDiscardConfirmationPresented = false
        var courseRegistrationCompletionRevision = 0
        var courseRegistrationExitRevision = 0

        init(isCourseTutorialCompleted: Bool) {
            route = isCourseTutorialCompleted ? .registration : .tutorial
            mapSelection = .init(isCourseTutorialCompleted: isCourseTutorialCompleted)
        }
    }

    enum Action {
        case tutorial(CourseRegistrationTutorialReducer.Action)
        case mapSelection(CourseRegistrationMapSelectionReducer.Action)
        case placeSearch(CourseRegistrationPlaceSearchReducer.Action)
        case errorDismissed(Int)
        case deactivated

        case registrationDiscardConfirmed
        case registrationDiscardCancelled

        case details(CourseRegistrationDetailsReducer.Action)
        case pinEditing(CourseRegistrationPinEditingReducer.Action)
    }

    private let tutorialReducer: CourseRegistrationTutorialReducer
    private let mapSelectionReducer: CourseRegistrationMapSelectionReducer
    private let pinEditingReducer: CourseRegistrationPinEditingReducer
    private let detailsReducer: CourseRegistrationDetailsReducer
    private let placeSearchReducer: CourseRegistrationPlaceSearchReducer

    private enum EffectID: Hashable {
        case errorDismissal
    }

    init(
        memberRepository: MemberRepository,
        courseRepository: CourseRepository,
        mapService: CourseRegistrationMapService? = nil,
        directionsService: KakaoDirectionsService? = nil
    ) {
        tutorialReducer = .init(memberRepository: memberRepository)
        let resolvedMapService = mapService ?? CourseRegistrationMapService()
        let resolvedDirectionsService = directionsService ?? KakaoDirectionsService()
        mapSelectionReducer = .init(mapService: resolvedMapService, directionsService: resolvedDirectionsService)
        pinEditingReducer = .init(mapService: resolvedMapService, directionsService: resolvedDirectionsService)
        detailsReducer = .init(courseRepository: courseRepository)
        placeSearchReducer = .init()
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .tutorial(let childAction):
            if case .delegate(let delegate) = childAction {
                return reduceTutorialDelegate(delegate, state: &state)
            }
            if case .deactivated = childAction {
                return tutorialReducer
                    .reduce(&state.tutorial, with: childAction)
                    .map(Action.tutorial)
            }
            guard state.route == .tutorial else { return .none }
            return tutorialReducer
                .reduce(&state.tutorial, with: childAction)
                .map(Action.tutorial)

        case .errorDismissed(let revision):
            guard state.errorRevision == revision else { return .none }
            state.errorMessage = nil

        case .deactivated:
            state.errorMessage = nil
            let hasPinEditing = state.pinEditing != nil
            return .run { send in
                await send(.tutorial(.deactivated))
                await send(.mapSelection(.deactivated))
                await send(.placeSearch(.deactivated))
                await send(.details(.deactivated))
                if hasPinEditing {
                    await send(.pinEditing(.deactivated))
                }
            }
            .cancelTask(id: EffectID.errorDismissal)

        case .mapSelection(let childAction):
            if case .delegate(let delegate) = childAction {
                return reduceMapSelectionDelegate(delegate, state: &state)
            }
            if case .deactivated = childAction {
                return mapSelectionReducer
                    .reduce(&state.mapSelection, with: childAction)
                    .map(Action.mapSelection)
            }
            guard state.route == .registration else { return .none }
            return mapSelectionReducer
                .reduce(&state.mapSelection, with: childAction)
                .map(Action.mapSelection)

        case .registrationDiscardConfirmed:
            guard state.isRegistrationDiscardConfirmationPresented else { return .none }
            state.isRegistrationDiscardConfirmationPresented = false
            state.courseRegistrationExitRevision += 1
            state.pinEditing = nil
            state.details = .init()
            return mapSelectionReducer
                .reduce(&state.mapSelection, with: .reset)
                .map(Action.mapSelection)

        case .registrationDiscardCancelled:
            state.isRegistrationDiscardConfirmationPresented = false

        case .details(let childAction):
            if case .delegate(let delegate) = childAction {
                return reduceDetailsDelegate(delegate, state: &state)
            }
            if case .deactivated = childAction {
                return detailsReducer
                    .reduce(&state.details, with: childAction)
                    .map(Action.details)
            }
            guard state.route == .details else { return .none }
            return detailsReducer
                .reduce(&state.details, with: childAction)
                .map(Action.details)

        case .placeSearch(let childAction):
            if case .delegate(let delegate) = childAction {
                return reducePlaceSearchDelegate(delegate, state: &state)
            }
            if case .deactivated = childAction {
                return placeSearchReducer
                    .reduce(&state.placeSearch, with: childAction)
                    .map(Action.placeSearch)
            }
            guard state.route.isPlaceSearch else { return .none }
            return placeSearchReducer
                .reduce(&state.placeSearch, with: childAction)
                .map(Action.placeSearch)

        case .pinEditing(let childAction):
            if case .delegate(let delegate) = childAction {
                return reducePinEditingDelegate(delegate, state: &state)
            }
            if case .deactivated = childAction, state.pinEditing != nil {
                return pinEditingReducer
                    .reduce(&state.pinEditing!, with: childAction)
                    .map(Action.pinEditing)
            }
            guard state.route == .pinEditing || state.route == .pinEditSearch,
                  state.pinEditing != nil
            else {
                return .none
            }
            return pinEditingReducer
                .reduce(&state.pinEditing!, with: childAction)
                .map(Action.pinEditing)

        }
        return .none
    }

    private func reduceDetailsDelegate(
        _ delegate: CourseRegistrationDetailsReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .backRequested:
            guard state.route == .details else { return .none }
            state.route = .registration
            return .none

        case .completionConfirmed:
            guard state.route == .details else { return .none }
            state.courseRegistrationCompletionRevision += 1
            return .none
        }
    }

    private func reduceTutorialDelegate(
        _ delegate: CourseRegistrationTutorialReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .completed:
            guard state.route == .tutorial else { return .none }
            state.route = .registration
            state.tutorialCompletionRevision += 1
            return mapSelectionReducer
                .reduce(&state.mapSelection, with: .prepareStartSelection)
                .map(Action.mapSelection)
        case .closeRequested:
            guard state.route == .tutorial else { return .none }
            state.courseRegistrationExitRevision += 1
            return .none
        }
    }

    private func reduceMapSelectionDelegate(
        _ delegate: CourseRegistrationMapSelectionReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .openSearch(let target):
            guard state.route == .registration,
                  state.mapSelection.canSearch(for: target)
            else {
                return .none
            }
            state.placeSearch = .init()
            state.route = .registrationSearch(target)
            return .none

        case .openPinEdit(let target, let originalPlace):
            guard state.route == .registration else { return .none }
            state.pinEditing = .init(target: target, originalPlace: originalPlace)
            state.route = .pinEditing
            return .none

        case .openDetails(let context):
            guard state.route == .registration else { return .none }
            state.route = .details
            return detailsReducer
                .reduce(&state.details, with: .start(context))
                .map(Action.details)

        case .closeRequested(let hasInput):
            guard state.route == .registration else { return .none }
            if hasInput {
                state.isRegistrationDiscardConfirmationPresented = true
            } else {
                state.courseRegistrationExitRevision += 1
            }
            return .none

        case .showError(let message):
            return presentError(message, state: &state)
        }
    }

    private func reducePinEditingDelegate(
        _ delegate: CourseRegistrationPinEditingReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .openSearch:
            guard state.route == .pinEditing else { return .none }
            state.placeSearch = .init()
            state.route = .pinEditSearch
            return .none

        case .cancelled:
            guard state.route == .pinEditing || state.route == .pinEditSearch else { return .none }
            state.pinEditing = nil
            state.route = .registration
            return .none

        case .completed(let target, let replacement, let routePath):
            guard state.route == .pinEditing else { return .none }
            state.pinEditing = nil
            state.route = .registration
            return mapSelectionReducer
                .reduce(&state.mapSelection, with: .pinEditApplied(target, replacement, routePath))
                .map(Action.mapSelection)

        case .showError(let message):
            return presentError(message, state: &state)
        }
    }

    private func reducePlaceSearchDelegate(
        _ delegate: CourseRegistrationPlaceSearchReducer.Delegate,
        state: inout State
    ) -> Effect<Action> {
        switch delegate {
        case .closeRequested:
            switch state.route {
            case .registrationSearch:
                state.route = .registration
            case .pinEditSearch:
                state.route = .pinEditing
            default:
                return .none
            }
            return .none

        case .resultSelected(let result):
            switch state.route {
            case .registrationSearch(let target):
                state.route = .registration
                return mapSelectionReducer
                    .reduce(&state.mapSelection, with: .searchResultSelected(target, result))
                    .map(Action.mapSelection)
            case .pinEditSearch:
                guard state.pinEditing != nil else { return .none }
                state.route = .pinEditing
                return pinEditingReducer
                    .reduce(&state.pinEditing!, with: .searchResultSelected(result))
                    .map(Action.pinEditing)
            default:
                return .none
            }

        case .regionSelected(let region):
            switch state.route {
            case .registrationSearch(let target):
                state.route = .registration
                return mapSelectionReducer
                    .reduce(&state.mapSelection, with: .regionSelected(target, region))
                    .map(Action.mapSelection)
            case .pinEditSearch:
                guard state.pinEditing != nil else { return .none }
                state.route = .pinEditing
                return pinEditingReducer
                    .reduce(&state.pinEditing!, with: .searchResultSelected(.init(
                        id: "region-\(region.id)",
                        title: region.displayName,
                        address: region.displayName,
                        coordinate: region.coordinate,
                        category: nil,
                        phone: nil
                    )))
                    .map(Action.pinEditing)
            default:
                return .none
            }
        }
    }

    private func presentError(_ message: String, state: inout State) -> Effect<Action> {
        state.errorRevision += 1
        state.errorMessage = message
        let revision = state.errorRevision
        return .run { send in
            do {
                try await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }
                await send(.errorDismissed(revision))
            } catch is CancellationError {
                return
            } catch {
                return
            }
        }
        .cancelTask(id: EffectID.errorDismissal)
    }
}

private extension CourseRegistrationReducer.State.Route {
    var isPlaceSearch: Bool {
        switch self {
        case .registrationSearch, .pinEditSearch:
            true
        default:
            false
        }
    }
}
