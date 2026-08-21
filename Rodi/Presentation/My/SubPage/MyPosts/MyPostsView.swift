//
//  MyPostsView.swift
//  Rodi
//

import SwiftUI

struct MyPostsView: View {
    @StateObject private var store: StoreOf<MyPostsReducer>
    @State private var activeMenuReviewID: Int?
    @State private var activeMenuCourseID: Int64?
    @State private var isCourseFilterExpanded = false

    let backAction: () -> Void
    let openPracticeRecords: () -> Void
    let openCourseRegistration: () -> Void
    let practiceRecordsRefreshRequested: () -> Void
    let reviewFlowFinishedRequestID: Int
    let editRequested: (Int) -> Void

    init(
        dependencies: MyPostsFeatureDependencies,
        backAction: @escaping () -> Void,
        openPracticeRecords: @escaping () -> Void,
        openCourseRegistration: @escaping () -> Void,
        practiceRecordsRefreshRequested: @escaping () -> Void,
        reviewFlowFinishedRequestID: Int,
        editRequested: @escaping (Int) -> Void
    ) {
        _store = StateObject(
            wrappedValue: Store(
                state: MyPostsReducer.State(),
                reducer: MyPostsReducer(
                    reviewRepository: dependencies.reviewRepository,
                    practiceRepository: dependencies.practiceRepository,
                    courseRepository: dependencies.courseRepository
                )
            )
        )
        self.backAction = backAction
        self.openPracticeRecords = openPracticeRecords
        self.openCourseRegistration = openCourseRegistration
        self.practiceRecordsRefreshRequested = practiceRecordsRefreshRequested
        self.reviewFlowFinishedRequestID = reviewFlowFinishedRequestID
        self.editRequested = editRequested
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MySubpageHeader(title: "내 활동", backAction: backAction)
                tabBar
                content
            }

            if store.state.reviews.deleteTargetReviewID != nil {
                reviewDeleteConfirmationDialog
                    .zIndex(20)
            }

            if store.state.courses.deleteTargetCourseID != nil {
                courseDeleteConfirmationDialog
                    .zIndex(20)
            }
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .overlayPreferenceValue(RodiDropdownAnchorPreferenceKey.self) { anchors in
            dropdownOverlay(anchors: anchors)
        }
        .rodiSnackbar(message: store.state.snackbarMessage)
        .onAppear {
            store.send(.appeared)
        }
        .onChange(of: reviewFlowFinishedRequestID) { requestID in
            guard requestID > 0 else { return }
            store.send(.reloadReviewsRequested)
        }
        .onChange(of: store.state.practiceRecordsRefreshRequestID) { requestID in
            guard requestID > 0 else { return }
            practiceRecordsRefreshRequested()
        }
        .onChange(of: store.state.pendingEditReviewID) { reviewID in
            guard let reviewID else { return }
            editRequested(reviewID)
            store.send(.editRequestHandled(reviewID))
        }
    }
}

// MARK: - Layout
private extension MyPostsView {

    var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(title: "등록한 코스", tab: .courses)
            tabButton(title: "작성한 후기", tab: .reviews)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RodiColor.gray200)
                .frame(height: 1)
        }
    }

    func tabButton(title: String, tab: MyPostsReducer.Tab) -> some View {
        let isSelected = store.state.selectedTab == tab

        return Button {
            closeDropdowns()
            store.send(.tabSelected(tab))
        } label:{
            Text(title)
                .font(.pretendard(size: 16, weight: isSelected ? .semibold : .medium))
                .tracking(-0.32)
                .foregroundStyle(isSelected ? RodiColor.black : RodiColor.gray400)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isSelected ? RodiColor.black : .clear)
                        .frame(height: 2)
                }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    var content: some View {
        switch store.state.selectedTab {
        case .courses:
            courseContent
        case .reviews:
            reviewContent
        }
    }

    var courseContent: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                courseFilterButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if store.state.courses.isInitialLoading, store.state.courses.items.isEmpty {
                ProgressView()
                    .tint(RodiColor.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.state.courses.items.isEmpty {
                MyCoursesEmptyState(
                    filter: store.state.courses.selectedFilter,
                    errorMessage: store.state.courses.errorMessage,
                    retry: { store.send(.retryTapped) },
                    openCourseRegistration: openCourseRegistration
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(store.state.courses.items) { course in
                            VStack(alignment: .leading, spacing: 24) {
                                MyCourseRow(
                                    course: course,
                                    isMenuExpanded: activeMenuCourseID == course.id,
                                    menuTapped: { toggleMenu(for: course.id) }
                                )

                                Rectangle()
                                    .fill(RodiColor.primaryMinus100)
                                    .frame(height: 1)
                            }
                        }

                        coursePaginationFooter
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { _ in closeDropdowns() }
                )
            }
        }
    }

    var courseFilterButton: some View {
        Button {
            activeMenuCourseID = nil
            activeMenuReviewID = nil
            isCourseFilterExpanded.toggle()
        } label: {
            HStack(spacing: 2) {
                Text(isCourseFilterExpanded ? "접기" : store.state.courses.selectedFilter.title)
                    .rodiTypography(.body3Medium)

                Image("ic_chevron_down")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(isCourseFilterExpanded ? 180 : 0))
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(RodiColor.gray700)
            .frame(minWidth: 44, minHeight: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCourseFilterExpanded ? "코스 상태 필터 닫기" : "코스 상태 필터 열기")
        .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
            [AnyHashable("course-filter"): $0]
        }
    }

    @ViewBuilder
    var coursePaginationFooter: some View {
        if store.state.courses.isNextPageLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let lastItem = store.state.courses.items.last,
                  store.state.courses.hasNextPage,
                  store.state.courses.errorMessage == nil {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    store.send(.courses(.lastItemAppeared(lastItem)))
                }
        }

        if let errorMessage = store.state.courses.errorMessage, !store.state.courses.items.isEmpty {
            MyPostsRetryFooter(message: errorMessage, retry: { store.send(.retryTapped) })
        }
    }

    @ViewBuilder
    var reviewContent: some View {
        if store.state.reviews.isInitialLoading, store.state.reviews.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.state.reviews.items.isEmpty {
            MyPostsEmptyState(
                errorMessage: store.state.reviews.errorMessage,
                retry: { store.send(.retryTapped) },
                openPracticeRecords: openPracticeRecords,
                hasPracticeRecords: store.state.reviews.hasPracticeRecords
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(store.state.reviews.items) { review in
                        VStack(alignment: .leading, spacing: 24) {
                            MyPostReviewRow(
                                review: review,
                                isMenuExpanded: activeMenuReviewID == review.id,
                                menuTapped: { toggleMenu(for: review.id) }
                            )

                            Rectangle()
                                .fill(RodiColor.primaryMinus100)
                                .frame(height: 1)
                        }
                    }

                    reviewPaginationFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 25)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in closeDropdowns() }
            )
        }
    }

    @ViewBuilder
    var reviewPaginationFooter: some View {
        if store.state.reviews.isNextPageLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let lastItem = store.state.reviews.items.last,
                  store.state.reviews.hasNextPage,
                  store.state.reviews.errorMessage == nil {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    store.send(.reviews(.lastItemAppeared(lastItem)))
                }
        }

        if let errorMessage = store.state.reviews.errorMessage, !store.state.reviews.items.isEmpty {
            MyPostsRetryFooter(message: errorMessage, retry: { store.send(.retryTapped) })
        }
    }

    @ViewBuilder
    func dropdownOverlay(
        anchors: [AnyHashable: Anchor<CGRect>]
    ) -> some View {
        if isCourseFilterExpanded,
           let anchor = anchors[AnyHashable("course-filter")] {
            menuOverlay(anchor: anchor) {
                RodiDropdownMenu(
                    options: MyPostsCourseFilter.allCases
                        .filter { $0 != store.state.courses.selectedFilter }
                        .map {
                        .init(id: $0.title, title: $0.title)
                        },
                    onSelect: { option in
                        guard let filter = MyPostsCourseFilter.allCases.first(where: { $0.title == option.id }) else {
                            return
                        }
                        isCourseFilterExpanded = false
                        store.send(.courses(.filterSelected(filter)))
                    }
                )
            }
        } else if let courseID = activeMenuCourseID,
                  let anchor = anchors[AnyHashable("course-\(courseID)")] {
            menuOverlay(anchor: anchor) {
                RodiDropdownMenu(
                    options: [.init(id: "delete", title: "삭제하기")],
                    onSelect: { _ in
                        activeMenuCourseID = nil
                        store.send(.courses(.deleteRequested(courseID)))
                    }
                )
            }
        } else if let reviewID = activeMenuReviewID,
                  let anchor = anchors[AnyHashable("review-\(reviewID)")] {
            menuOverlay(anchor: anchor) {
                RodiDropdownMenu(
                    options: [
                        .init(id: "edit", title: "수정하기"),
                        .init(id: "delete", title: "삭제하기")
                    ],
                    onSelect: { option in
                        activeMenuReviewID = nil
                        if option.id == "edit" {
                            store.send(.reviews(.editRequested(reviewID)))
                        } else {
                            store.send(.reviews(.deleteRequested(reviewID)))
                        }
                    }
                )
            }
        }
    }

    func menuOverlay<Menu: View>(
        anchor: Anchor<CGRect>,
        @ViewBuilder menu: @escaping () -> Menu
    ) -> some View {
        GeometryReader { proxy in
            let triggerFrame = proxy[anchor]

            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { closeDropdowns() }

                menu()
                    .alignmentGuide(.leading) { dimensions in
                        dimensions[.trailing] - triggerFrame.maxX
                    }
                    .alignmentGuide(.top) { dimensions in
                        dimensions[.top] - triggerFrame.maxY - 4
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in closeDropdowns() }
            )
        }
        .ignoresSafeArea()
        .zIndex(10)
    }

    func toggleMenu(for reviewID: Int) {
        activeMenuCourseID = nil
        isCourseFilterExpanded = false
        activeMenuReviewID = activeMenuReviewID == reviewID ? nil : reviewID
    }

    func toggleMenu(for courseID: Int64) {
        activeMenuReviewID = nil
        isCourseFilterExpanded = false
        activeMenuCourseID = activeMenuCourseID == courseID ? nil : courseID
    }

    func closeDropdowns() {
        activeMenuReviewID = nil
        activeMenuCourseID = nil
        isCourseFilterExpanded = false
    }

    var reviewDeleteConfirmationDialog: some View {
        ReviewDeleteConfirmationDialog(
            isDeleting: store.state.reviews.isDeleting,
            errorMessage: store.state.reviews.deleteErrorMessage,
            deleteAction: { store.send(.reviews(.deleteConfirmed)) },
            cancelAction: { store.send(.reviews(.deleteCancelled)) }
        )
    }

    var courseDeleteConfirmationDialog: some View {
        CourseDeleteConfirmationDialog(
            isDeleting: store.state.courses.isDeleting,
            errorMessage: store.state.courses.deleteErrorMessage,
            deleteAction: { store.send(.courses(.deleteConfirmed)) },
            cancelAction: { store.send(.courses(.deleteCancelled)) }
        )
    }
}
