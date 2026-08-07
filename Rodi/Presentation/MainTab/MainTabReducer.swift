//
//  MainTabReducer.swift
//  Rodi
//

import Foundation

enum MainTabIntent: Equatable {
    case presentHomeList
    case openHomePlace(PlaceListItem)
    case openMyProfile
    case openMySavedPlaces
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
        fileprivate var nextHomePlaceSelectionRequestID = 0
    }

    enum Action {
        case homeTabTapped
        case homeTabSelected
        
        case myTabTapped
        
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

// MARK: Core Logics
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
                return .none
            }

            state.authenticationIntent = .openMyProfile

        case .navigationRequested(let intent):
            state.selectedTab = tab(for: intent)
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
        case .presentHomeList, .openHomePlace:
            .home
        case .openMyProfile, .openMySavedPlaces:
            .my
        }
    }
}
