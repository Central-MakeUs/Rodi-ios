import SwiftUI

struct CourseRegistrationView: View {
    @EnvironmentObject private var networkConnectionMonitor: NetworkConnectionMonitor
    @StateObject private var store: StoreOf<CourseRegistrationReducer>
    @State private var handledCompletionRevision = 0
    @State private var handledCourseRegistrationCompletionRevision = 0
    @State private var handledCourseRegistrationExitRevision = 0
    @State private var isMapNetworkUnavailableScreenPresented = false

    let closeAction: () -> Void
    let tutorialCompletedAction: () -> Void
    private let courseRegistrationCompletedAction: () -> Void

    init(presentation: CourseRegistrationPresentation, dependencies: CourseRegistrationFeatureDependencies) {
        closeAction = presentation.close
        tutorialCompletedAction = presentation.tutorialCompleted
        courseRegistrationCompletedAction = presentation.registrationCompleted
        _store = StateObject(wrappedValue: Store(
            state: .init(isCourseTutorialCompleted: presentation.isTutorialCompleted),
            reducer: CourseRegistrationReducer(
                memberRepository: dependencies.memberRepository,
                courseRepository: dependencies.courseRepository
            )
        ))
    }

    var body: some View {
        routeContent
            .rodiSnackbar(message: store.state.errorMessage)
            .overlay { discardConfirmation }
            .overlay { submissionPresentation }
            .overlay {
                if isMapNetworkUnavailableScreenPresented {
                    MapNetworkUnavailableView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .onChange(of: store.state.tutorialCompletionRevision) { revision in
                guard revision > handledCompletionRevision else { return }
                handledCompletionRevision = revision
                tutorialCompletedAction()
            }
            .onChange(of: store.state.courseRegistrationCompletionRevision) { revision in
                guard revision > handledCourseRegistrationCompletionRevision else { return }
                handledCourseRegistrationCompletionRevision = revision
                courseRegistrationCompletedAction()
            }
            .onChange(of: store.state.courseRegistrationExitRevision) { revision in
                guard revision > handledCourseRegistrationExitRevision else { return }
                handledCourseRegistrationExitRevision = revision
                closeAction()
            }
            .onDisappear { store.send(.deactivated) }
            .task(id: shouldDelayMapNetworkUnavailableScreen) {
                guard shouldDelayMapNetworkUnavailableScreen else {
                    isMapNetworkUnavailableScreenPresented = false
                    return
                }

                do {
                    try await Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    return
                }

                guard !Task.isCancelled,
                      shouldDelayMapNetworkUnavailableScreen
                else {
                    return
                }
                isMapNetworkUnavailableScreenPresented = true
            }
    }

    @ViewBuilder
    private var routeContent: some View {
        switch store.state.route {
        case .tutorial:
            CourseRegistrationTutorialView(
                state: store.state.tutorial,
                send: { store.send(.tutorial($0)) }
            )
        case .registration:
            CourseRegistrationMapSelectionView(
                state: store.state.mapSelection,
                send: { store.send(.mapSelection($0)) }
            )
        case .registrationSearch, .pinEditSearch:
            CourseRegistrationPlaceSearchView(
                state: store.state.placeSearch,
                send: { store.send(.placeSearch($0)) }
            )
        case .pinEditing:
            if let pinEditing = store.state.pinEditing {
                CourseRegistrationPinEditingView(
                    state: pinEditing,
                    waypoints: store.state.mapSelection.waypoints,
                    selectedPlaces: store.state.mapSelection.selectedPlaces,
                    send: { store.send(.pinEditing($0)) }
                )
            }
        case .details:
            CourseRegistrationDetailsView(
                state: store.state.details,
                send: { store.send(.details($0)) }
            )
        }
    }

    @ViewBuilder
    private var discardConfirmation: some View {
        if store.state.isRegistrationDiscardConfirmationPresented {
            ReviewDiscardConfirmationView(
                send: { action in
                    switch action {
                    case .discard:
                        store.send(.registrationDiscardConfirmed)
                    case .keepWriting:
                        store.send(.registrationDiscardCancelled)
                    }
                },
                confirmAction: RegistrationDiscardAction.discard,
                cancelAction: RegistrationDiscardAction.keepWriting
            )
        }
    }

    private var shouldDelayMapNetworkUnavailableScreen: Bool {
        networkConnectionMonitor.status == .disconnected && isMapRoute
    }

    private var isMapRoute: Bool {
        switch store.state.route {
        case .registration, .pinEditing:
            true
        case .tutorial, .registrationSearch, .pinEditSearch, .details:
            false
        }
    }

    @ViewBuilder
    private var submissionPresentation: some View {
        if store.state.details.isSubmitting {
            CourseRegistrationSubmittingDialog()
        } else if store.state.details.isCompletionPresented {
            CourseRegistrationCompletionDialog(
                confirmAction: { store.send(.details(.completionConfirmed)) }
            )
        }
    }
}

private enum RegistrationDiscardAction {
    case discard
    case keepWriting
}
