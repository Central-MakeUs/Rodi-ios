import SwiftUI

/// BottomSheet root가 계산한 높이·gesture 결과를 사용해 route별 콘텐츠만 렌더링한다.
struct HomeBottomSheetRouteContent: View {
    let state: HomeBottomSheetReducer.State
    let screenSafeAreaInsets: EdgeInsets
    let recommendationHeight: CGFloat
    let recommendationOpacity: CGFloat
    let fixedSheetHeight: CGFloat
    let fixedSheetOffset: CGFloat
    let fixedSheetOpacity: CGFloat
    let courseSheetHeight: CGFloat
    let courseDetailHeight: CGFloat
    let parkingSheetHeight: CGFloat
    let isSettling: Bool
    let userLocation: RodiCoordinate?
    let hasLocationPermission: Bool
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: () async throws -> Void
    let recommendationPanChanged: (CGFloat) -> Void
    let recommendationPanEnded: (CGFloat) -> Void
    let detailPanChanged: (CGFloat) -> Void
    let detailPanEnded: (CGFloat, CGFloat) -> Void
    let coursePanChanged: (CGFloat) -> Void
    let coursePanEnded: (CGFloat) -> Void
    let sendRecommendation: (RecommendListBottomSheetReducer.Action) -> Void
    let sendFilter: (FilterBottomSheetReducer.Action) -> Void
    let sendCourseDetail: (CourseDetailBottomSheetReducer.Action) -> Void
    let sendParkingDetail: (ParkingDetailBottomSheetReducer.Action) -> Void
    let requestLocationPermission: () -> Void
    let courseDetailHeightChanged: (CGFloat) -> Void
    let parkingDetailHeightChanged: (CGFloat) -> Void

    var body: some View {
        switch state.route {
        case .recommendList:
            recommendationContent
        case .filter:
            fixedSheet(height: fixedSheetHeight, dismissThreshold: 72, contentBottomInset: screenSafeAreaInsets.bottom) {
                FilterBottomSheetView(state: state.filter, send: sendFilter)
            }
        case .courseDetail:
            courseDetailContent
        case .parkingDetail:
            parkingDetailContent
        }
    }
}

private extension HomeBottomSheetRouteContent {
    var recommendationContent: some View {
        Group {
            if state.recommendList.presentation == .expanded {
                VStack(spacing: 0) {
                    RecommendListBottomSheetView(
                        state: state.recommendList,
                        send: sendRecommendation,
                        debugReviewTestAction: debugReviewTestAction,
                        debugHardWithdrawAction: debugHardWithdrawAction,
                        titlePanEnabled: !isSettling,
                        titlePanChanged: recommendationPanChanged,
                        titlePanEnded: recommendationPanEnded
                    )
                    .padding(.bottom, screenSafeAreaInsets.bottom)
                }
                .padding(.top, screenSafeAreaInsets.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(RodiColor.white)
                .ignoresSafeArea()
            } else {
                HomeBottomSheetChrome {
                    VStack(spacing: 0) {
                        HomeBottomSheetDragHandle(
                            isEnabled: !isSettling,
                            bottomSpacing: 0,
                            onChanged: recommendationPanChanged,
                            onEnded: recommendationPanEnded
                        )
                        RecommendListBottomSheetView(
                            state: state.recommendList,
                            send: sendRecommendation,
                            debugReviewTestAction: debugReviewTestAction,
                            debugHardWithdrawAction: debugHardWithdrawAction,
                            titlePanEnabled: !isSettling,
                            titlePanChanged: recommendationPanChanged,
                            titlePanEnded: recommendationPanEnded
                        )
                        .padding(.bottom, screenSafeAreaInsets.bottom)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
        }
        .frame(height: recommendationHeight, alignment: .top)
        .opacity(recommendationOpacity)
    }

    @ViewBuilder
    var courseDetailContent: some View {
        if state.courseDetail.detail != nil {
            if state.courseDetail.presentation == .expandedDetail {
                Color.clear
            } else {
                VStack(spacing: 0) {
                    HomeBottomSheetDragHandle(
                        isEnabled: !isSettling,
                        bottomSpacing: 0,
                        onChanged: coursePanChanged,
                        onEnded: coursePanEnded
                    )
                    CourseDetailBottomSheetView(
                        state: state.courseDetail,
                        send: sendCourseDetail,
                        userLocation: userLocation,
                        hasLocationPermission: hasLocationPermission,
                        requestLocationPermission: requestLocationPermission,
                        titlePanEnabled: !isSettling,
                        titlePanChanged: coursePanChanged,
                        titlePanEnded: coursePanEnded
                    )
                }
                .fixedSize(horizontal: false, vertical: true)
                .background { BottomSheetContentHeightObserver(onHeightChanged: courseDetailHeightChanged) }
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(height: courseSheetHeight, alignment: .top)
                .background(RodiColor.white)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 20))
                .shadow(color: RodiColor.black.opacity(0.08), radius: 4, x: 0, y: -3)
                .opacity(HomeBottomSheetLayout.dismissalOpacity(visibleHeight: courseSheetHeight, totalHeight: courseDetailHeight))
            }
        } else if state.resolvingPlaceID != nil || state.isDetailPresentationPending {
            recommendationContent
        }
    }

    @ViewBuilder
    var parkingDetailContent: some View {
        if state.parkingDetail.detail != nil {
            fixedSheet(height: parkingSheetHeight, dismissThreshold: 48) {
                ParkingDetailBottomSheetView(
                    state: state.parkingDetail,
                    send: sendParkingDetail,
                    userLocation: userLocation,
                    hasLocationPermission: hasLocationPermission,
                    requestLocationPermission: requestLocationPermission,
                    titlePanEnabled: !isSettling,
                    titlePanChanged: detailPanChanged,
                    titlePanEnded: { detailPanEnded($0, 48) }
                )
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, screenSafeAreaInsets.bottom)
                .background { BottomSheetContentHeightObserver(onHeightChanged: parkingDetailHeightChanged) }
            }
        } else if state.resolvingPlaceID != nil || state.isDetailPresentationPending {
            recommendationContent
        }
    }

    func fixedSheet<Content: View>(
        height: CGFloat,
        dismissThreshold: CGFloat,
        contentBottomInset: CGFloat = 0,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        HomeBottomSheetChrome {
            VStack(spacing: 0) {
                HomeBottomSheetDragHandle(
                    isEnabled: !isSettling,
                    onChanged: detailPanChanged,
                    onEnded: { detailPanEnded($0, dismissThreshold) }
                )
                content()
                    .padding(.bottom, contentBottomInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(height: height, alignment: .top)
        .offset(y: fixedSheetOffset)
        .opacity(fixedSheetOpacity)
    }
}
