//
//  HomeView.swift
//  Rodi
//

import SwiftUI
import UIKit

/// Home feature의 진입점. Store와 Router를 만들고 화면 조합 View에 전달만 한다.
struct HomeView: View {
    @StateObject private var homeStore: StoreOf<HomeReducer>
    @ObservedObject private var router: HomeRouter
    
    private let isHomeTabSelected: () -> Bool
    
    private let onAuthenticationRequired: () -> Void
    
    private let onBottomSheetStateChanged: (HomeBottomSheetState) -> Void
    
    private let bottomTabBarHeight: CGFloat
    
    private let placeRepository: PlaceRepository
    
    private let memberRepository: MemberRepository
    
    private let recentSearchRepository: RecentSearchRepository
    
    private let tokenStore: TokenStoring

    init(
        router: HomeRouter,
        isHomeTabSelected: @escaping () -> Bool,
        onAuthenticationRequired: @escaping () -> Void,
        onBottomSheetStateChanged: @escaping (HomeBottomSheetState) -> Void,
        bottomTabBarHeight: CGFloat,
        dependencies: AppDependencies
    ) {
        self.router = router
        self.isHomeTabSelected = isHomeTabSelected
        self.onAuthenticationRequired = onAuthenticationRequired
        self.onBottomSheetStateChanged = onBottomSheetStateChanged
        self.bottomTabBarHeight = bottomTabBarHeight
        placeRepository = dependencies.placeRepository
        memberRepository = dependencies.memberRepository
        recentSearchRepository = dependencies.recentSearchRepository
        tokenStore = dependencies.tokenStore
        
        _homeStore = StateObject(
            wrappedValue: Store(
                state: HomeReducer.State(),
                reducer: HomeReducer(
                    placeRepository: dependencies.placeRepository,
                    memberRepository: dependencies.memberRepository,
                    tokenStore: dependencies.tokenStore
                )
            )
        )
    }

    var body: some View {
        HomeBottomSheetView(
            homeStore: homeStore,
            router: router,
            isHomeTabSelected: isHomeTabSelected,
            onSearchRequested: presentSearch,
            bottomTabBarHeight: bottomTabBarHeight,
            placeRepository: placeRepository
        )
        .homeInteractions(
            homeStore: homeStore,
            openSettingsAction: AppSettings.openSetting
        )
        
        // 관찰 대상 값이 바뀔 때마다 실행
        .onChange(of: homeStore.state.presentation.authenticationRequestID) { requestID in
            guard requestID > 0 else { return }
            onAuthenticationRequired()
        }
        
        // View가 화면에 처음 나타날 때 실행
        .onAppear {
            onBottomSheetStateChanged(homeStore.state.bottomSheet.bottomSheetState)
        }
        
        
        .onChange(of: homeStore.state.bottomSheet.bottomSheetState) { state in
            onBottomSheetStateChanged(state)
        }
        
        // 새 화면을 전체 화면으로 띄우는 SwiftUI의 모달 표시 방식
        .fullScreenCover(item: searchPresentationBinding) { presentation in
            switch presentation {
            case .search(let origin):
                HomeSearchView(
                    origin: origin,
                    onPlaceSelected: { placeID, placeName in
                        router.completeSearch(placeID: placeID, name: placeName)
                    },
                    onDismiss: router.dismissPresentation,
                    placeRepository: placeRepository,
                    recentSearchRepository: recentSearchRepository
                )
            }
        }
    }
}


extension HomeView {

    private func presentSearch() {
        guard [tokenStore.accessToken, tokenStore.refreshToken].contains(
            where: {
                $0?.isEmpty == false
            }) else {
            onAuthenticationRequired()
            return
        }
        
        router.presentSearch(origin: homeStore.state.map.userLocationCoordinate ?? .southKoreaCenter)
    }

    private var searchPresentationBinding: Binding<HomePresentation?> {
        Binding(
            get: { router.presentedPresentation },
            set: { presentation in
                if presentation == nil {
                    router.dismissPresentation()
                }
            }
        )
    }

    
}

