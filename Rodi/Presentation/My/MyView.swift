//
//  MyView.swift
//  Rodi
//

import Clarity
import SwiftUI

struct MyView: View {
    @ObservedObject var router: MyRouter
    @StateObject private var store: StoreOf<MyReducer>

    let isMyTabSelected: () -> Bool
    let navigate: (MainTabIntent) -> Void
    let onLogoutCompleted: () -> Void
    private let memberRepository: MemberRepository
    private let placeRepository: PlaceRepository

    init(
        router: MyRouter,
        isMyTabSelected: @escaping () -> Bool,
        navigate: @escaping (MainTabIntent) -> Void,
        onLogoutCompleted: @escaping () -> Void,
        dependencies: AppDependencies
    ) {
        self.router = router
        self.isMyTabSelected = isMyTabSelected
        self.navigate = navigate
        self.onLogoutCompleted = onLogoutCompleted
        _store = StateObject(
            wrappedValue: Store(
                state: MyReducer.State(),
                reducer: MyReducer(
                    authRepository: dependencies.authRepository,
                    memberRepository: dependencies.memberRepository,
                    recentLoginProviderStore: dependencies.recentLoginProviderStore
                )
            )
        )
        memberRepository = dependencies.memberRepository
        placeRepository = dependencies.placeRepository
    }

    var body: some View {
        NavigationStack(path: router.pathBinding) {
            MyProfileView(
                profile: store.state.profile,
                isLoading: store.state.isLoadingProfile,
                hasCompletedInitialLoad: store.state.hasCompletedInitialLoad,
                errorMessage: store.state.profileErrorMessage,
                openSettings: { router.push(.settings) },
                openDrivingGoal: { router.push(.drivingGoal) },
                openSavedPlaces: { router.push(.savedPlaces) },
                retry: { store.send(.retryProfileTapped) }
            )
            .navigationDestination(for: MyRoute.self) { route in
                destinationView(for: route)
                    .background(MyInteractivePopGestureEnabler())
                    .myEdgeSwipeBack(route: route, router: router)
            }
        }
        .rodiSnackbar(message: store.state.snackbarMessage)
        .onAppear {
            guard isMyTabSelected() else { return }
            store.send(.appeared)
        }
        .onChange(of: isMyTabSelected()) { isSelected in
            guard isSelected else { return }
            store.send(.appeared)
        }
        .onChange(of: store.state.didEndSessionRequestID) { requestID in
            guard requestID > 0 else { return }
            router.popToRoot()
            onLogoutCompleted()
        }
        .clarityMask()
    }

}

// MARK: Layout
private extension MyView {

    @ViewBuilder
    private func destinationView(for route: MyRoute) -> some View {
        switch route {
        case .settings:
            MySettingsView(backAction: router.pop, navigate: router.push)
        case .drivingGoal:
            MyDrivingGoalView(
                initialDrivingGoal: "",
                memberRepository: memberRepository,
                onUpdated: { store.send(.drivingGoalUpdated($0)) },
                backAction: router.pop
            )
        case .savedPlaces:
            SavedPlacesView(
                placeRepository: placeRepository,
                backAction: router.pop,
                selectPlaceAction: { item in
                    RodiAnalytics.track(.savedPlaceSelected)
                    router.popToRoot()
                    navigate(.openHomePlace(id: item.id))
                }
            )
        case .permissions:
            MyPermissionSettingsView(backAction: router.pop)
        case .terms:
            MyTermsView(backAction: router.pop, navigate: router.push)
        case .licenses:
            MyOpenSourceLicenseView(backAction: router.pop)
        case .accountManagement:
            MyAccountManagementView(
                backAction: router.pop,
                navigate: router.push,
                logoutAction: { store.send(.logoutConfirmed) },
                withdrawalAction: { store.send(.withdrawalConfirmed) }
            )
        case .contact:
            MyContactView(backAction: router.pop)
        case .legalDocument(let document):
            MyLegalDocumentView(document: document, backAction: router.pop)
        }
    }

}
