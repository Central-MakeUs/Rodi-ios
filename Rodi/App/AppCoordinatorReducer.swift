//
//  AppCoordinatorReducer.swift
//  Rodi
//

import Foundation

@MainActor
struct AppCoordinatorReducer: Reducer {
    enum Route {
        case onboarding(OnboardingLaunchContext)
        case mainTabs
    }

    enum OnboardingLaunchContext {
        case normal
        case automaticLogin(SocialLoginProvider)
    }

    enum Presentation {
        case loginRequired
        #if DEBUG
        case debugOnboarding
        #endif
    }

    struct State {
        var route: Route
        var selectedTab: RodiTab = .home
        var pendingHomePlaceSelection: PlaceListItem?
        var homeBottomSheetState: HomeBottomSheetState = .collapsed
        var homeTabTapRequestID = 0
        var isMyDetailPresented = false
        var presentation: Presentation?

        init(hasSeenOnboarding: Bool) {
            route = hasSeenOnboarding ? .mainTabs : .onboarding(.normal)
        }
    }

    enum Action {
        case onboardingCompleted
        case logoutCompleted
        case selectedTabChanged(RodiTab)
        case homeTabTapped
        case myTabTapped(isAuthenticated: Bool)
        case loginRequiredRequested
        case savedPlaceSelected(PlaceListItem)
        case pendingHomePlaceSelectionChanged(PlaceListItem?)
        case homeBottomSheetStateChanged(HomeBottomSheetState)
        case homeTabTapRequestIDChanged(Int)
        case myDetailPresentationChanged(Bool)
        case loginRequiredDismissed
        case loginRequested(SocialLoginProvider)
        case automaticLoginConsumed
        #if DEBUG
        case debugOnboardingRequested
        case debugOnboardingDismissed
        #endif
    }

    private let preferencesStore: AppPreferencesStore
    private let draftStore: OnboardingDraftStore

    init(
        preferencesStore: AppPreferencesStore,
        draftStore: OnboardingDraftStore
    ) {
        self.preferencesStore = preferencesStore
        self.draftStore = draftStore
    }

    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .onboardingCompleted:
            preferencesStore.markOnboardingSeen()
            state.route = .mainTabs
            state.selectedTab = .home

        case .logoutCompleted:
            draftStore.clear()
            preferencesStore.resetOnboardingSeen()
            state.route = .onboarding(.normal)
            state.selectedTab = .home
            state.pendingHomePlaceSelection = nil
            state.presentation = nil

        case .selectedTabChanged(let tab):
            state.selectedTab = tab

        case .homeTabTapped:
            if state.selectedTab == .home {
                state.homeTabTapRequestID += 1
            } else {
                state.selectedTab = .home
            }

        case .myTabTapped(let isAuthenticated):
            if isAuthenticated {
                state.selectedTab = .my
            } else {
                state.presentation = .loginRequired
            }

        case .loginRequiredRequested:
            state.presentation = .loginRequired

        case .savedPlaceSelected(let place):
            state.pendingHomePlaceSelection = place
            state.selectedTab = .home

        case .pendingHomePlaceSelectionChanged(let place):
            state.pendingHomePlaceSelection = place

        case .homeBottomSheetStateChanged(let bottomSheetState):
            state.homeBottomSheetState = bottomSheetState

        case .homeTabTapRequestIDChanged(let requestID):
            state.homeTabTapRequestID = requestID

        case .myDetailPresentationChanged(let isPresented):
            state.isMyDetailPresented = isPresented

        case .loginRequiredDismissed:
            state.presentation = nil

        case .loginRequested(let provider):
            state.presentation = nil
            state.selectedTab = .home
            state.route = .onboarding(.automaticLogin(provider))

        case .automaticLoginConsumed:
            if case .onboarding(.automaticLogin) = state.route {
                state.route = .onboarding(.normal)
            }

        #if DEBUG
        case .debugOnboardingRequested:
            state.presentation = .debugOnboarding
        case .debugOnboardingDismissed:
            state.presentation = nil
        #endif
        }

        return .none
    }
}
