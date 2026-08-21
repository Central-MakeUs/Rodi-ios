//
//  MainTabReducer.swift
//  Rodi
//

import Foundation

enum MainTabIntent: Equatable {
    case openHome
    case presentHomeList
    case openHomePlace(PlaceListItem)
    case openMyProfile
    case openMySavedPlaces
    case openMyPracticeRecords
    case openCourseRegistration
}

struct HomePlaceSelectionRequest: Equatable {
    let id: Int
    let place: PlaceListItem
}

@MainActor
struct MainTabReducer: Reducer {
    struct State {
        var selectedTab: RodiTab = .home
        var navigationIntent: MainTabIntent?
        var authenticationIntent: MainTabIntent?
        var isHomeBottomTabBarVisible = true
        var homePlaceSelectionRequest: HomePlaceSelectionRequest?
        var myDataRefreshRequestID = 0
        var practiceRecordsNavigationRequestID = 0
        fileprivate var nextHomePlaceSelectionRequestID = 0
    }

    enum Action {
        case homeTabTapped
        case homeTabSelected
        
        case myTabTapped
        case registerTabTapped
        case courseRegistrationExited
        
        case navigationRequested(MainTabIntent)
        
        case navigationHandled
        
        case authenticationRequestHandled

        case homePlaceSelectionHandled(Int)
        
        case homeBottomTabBarVisibilityChanged(Bool)
    }

    private let tokenStore: TokenStoring

    init(tokenStore: TokenStoring) {
        self.tokenStore = tokenStore
    }
}


// MARK: - Core Logics
extension MainTabReducer {
    
    func reduce(_ state: inout State, with action: Action) -> Effect<Action> {
        switch action {
        case .homeTabTapped:
            if state.selectedTab == .home {
                state.navigationIntent = .presentHomeList
            } else {
                state.selectedTab = .home
            }

        case .homeTabSelected:
            state.selectedTab = .home

        case .myTabTapped:
            guard !hasActiveSession else {
                state.selectedTab = .my
                requestMyDataRefresh(state: &state)
                return .none
            }

            state.authenticationIntent = .openMyProfile

        case .registerTabTapped:
            guard hasActiveSession else {
                state.authenticationIntent = .openCourseRegistration
                return .none
            }
            state.selectedTab = .register

        case .courseRegistrationExited:
            state.selectedTab = .home

        case .navigationRequested(let intent):
            let selectedTab = tab(for: intent)
            state.selectedTab = selectedTab
            if selectedTab == .my {
                requestMyDataRefresh(state: &state)
            }
            if case .openMyPracticeRecords = intent {
                state.practiceRecordsNavigationRequestID += 1
            }
            state.navigationIntent = intent
            if case .openHomePlace(let place) = intent {
                state.nextHomePlaceSelectionRequestID += 1
                state.homePlaceSelectionRequest = HomePlaceSelectionRequest(
                    id: state.nextHomePlaceSelectionRequestID,
                    place: place
                )
            }

        case .navigationHandled:
            state.navigationIntent = nil

        case .authenticationRequestHandled:
            state.authenticationIntent = nil

        case .homePlaceSelectionHandled(let id):
            guard state.homePlaceSelectionRequest?.id == id else { return .none }
            state.homePlaceSelectionRequest = nil

        case .homeBottomTabBarVisibilityChanged(let isVisible):
            state.isHomeBottomTabBarVisible = isVisible
        }

        return .none
    }
    
    private var hasActiveSession: Bool {
        [tokenStore.accessToken, tokenStore.refreshToken].contains { $0?.isEmpty == false }
    }

    private func tab(for intent: MainTabIntent) -> RodiTab {
        switch intent {
        case .openHome, .presentHomeList, .openHomePlace:
            .home
        case .openMyProfile, .openMySavedPlaces, .openMyPracticeRecords:
            .my
        case .openCourseRegistration:
            .register
        }
    }

    private func requestMyDataRefresh(state: inout State) {
        state.myDataRefreshRequestID += 1
    }
}
