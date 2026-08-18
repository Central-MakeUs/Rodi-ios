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
        reviewRepository: ReviewRepository,
        practiceRepository: PracticeRepository,
        courseRepository: CourseRepository,
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
                    reviewRepository: reviewRepository,
                    practiceRepository: practiceRepository,
                    courseRepository: courseRepository
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

            if store.state.deleteTargetReviewID != nil {
                reviewDeleteConfirmationDialog
                    .zIndex(20)
            }

            if store.state.deleteTargetCourseID != nil {
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
            store.send(.editRequestHandled(reviewID: reviewID))
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

            if store.state.isCourseInitialLoading, store.state.courseItems.isEmpty {
                ProgressView()
                    .tint(RodiColor.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.state.courseItems.isEmpty {
                MyCoursesEmptyState(
                    filter: store.state.selectedCourseFilter,
                    errorMessage: store.state.courseErrorMessage,
                    retry: { store.send(.retryTapped) },
                    openCourseRegistration: openCourseRegistration
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(store.state.courseItems) { course in
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
                Text(isCourseFilterExpanded ? "접기" : store.state.selectedCourseFilter.title)
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
        if store.state.isCourseNextPageLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let lastItem = store.state.courseItems.last,
                  store.state.hasNextCoursePage,
                  store.state.courseErrorMessage == nil {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    store.send(.courseLastItemAppeared(lastItem))
                }
        }

        if let errorMessage = store.state.courseErrorMessage, !store.state.courseItems.isEmpty {
            MyPostsRetryFooter(message: errorMessage, retry: { store.send(.retryTapped) })
        }
    }

    @ViewBuilder
    var reviewContent: some View {
        if store.state.isInitialLoading, store.state.items.isEmpty {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.state.items.isEmpty {
            MyPostsEmptyState(
                errorMessage: store.state.errorMessage,
                retry: { store.send(.retryTapped) },
                openPracticeRecords: openPracticeRecords,
                hasPracticeRecords: store.state.hasPracticeRecords
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(store.state.items) { review in
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
        }
    }

    @ViewBuilder
    var reviewPaginationFooter: some View {
        if store.state.isNextPageLoading {
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
        } else if let lastItem = store.state.items.last,
                  store.state.hasNextPage,
                  store.state.errorMessage == nil {
            Color.clear
                .frame(height: 1)
                .onAppear {
                    store.send(.lastItemAppeared(lastItem))
                }
        }

        if let errorMessage = store.state.errorMessage, !store.state.items.isEmpty {
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
                    options: MyPostsReducer.CourseFilter.allCases
                        .filter { $0 != store.state.selectedCourseFilter }
                        .map {
                        .init(id: $0.title, title: $0.title)
                        },
                    onSelect: { option in
                        guard let filter = MyPostsReducer.CourseFilter.allCases.first(where: { $0.title == option.id }) else {
                            return
                        }
                        isCourseFilterExpanded = false
                        store.send(.courseFilterSelected(filter))
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
                        store.send(.deleteCourseRequested(courseID: courseID))
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
                            store.send(.editRequested(reviewID: reviewID))
                        } else {
                            store.send(.deleteRequested(reviewID: reviewID))
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
            isDeleting: store.state.isDeleting,
            errorMessage: store.state.deleteErrorMessage,
            deleteAction: { store.send(.deleteConfirmed) },
            cancelAction: { store.send(.deleteCancelled) }
        )
    }

    var courseDeleteConfirmationDialog: some View {
        CourseDeleteConfirmationDialog(
            isDeleting: store.state.isDeletingCourse,
            errorMessage: store.state.courseDeleteErrorMessage,
            deleteAction: { store.send(.deleteCourseConfirmed) },
            cancelAction: { store.send(.deleteCourseCancelled) }
        )
    }
}

private struct MyCourseRow: View {
    let course: MyCourseItem
    let isMenuExpanded: Bool
    let menuTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.pretendard(size: 15, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) {
                    Button(action: menuTapped) {
                        Image("ic_more_horizontal_circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                                [AnyHashable("course-\(course.id)"): $0]
                            }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel(isMenuExpanded ? "코스 메뉴 닫기" : "코스 메뉴 열기")
                }

            HStack(spacing: 4) {
                Text(course.approvalStatus.title)
                    .font(.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(statusTextColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text("･")
                Text(createdAtText)
            }
            .font(.pretendard(size: 13, weight: .medium))
            .tracking(-0.26)
            .foregroundStyle(RodiColor.gray600)
        }
    }

    private var statusTextColor: Color {
        switch course.approvalStatus {
        case .approved: Color(hex: 0x04B3AA)
        case .pending: RodiColor.gray50
        case .rejected: Color(hex: 0xFF3019)
        }
    }

    private var statusBackgroundColor: Color {
        switch course.approvalStatus {
        case .approved: Color(hex: 0xE4FAF7)
        case .pending: RodiColor.gray400
        case .rejected: Color(hex: 0xFFEDF6)
        }
    }

    private var createdAtText: String {
        let dateComponents = course.createdAt.prefix(10).split(separator: "-")
        guard dateComponents.count == 3,
              dateComponents[0].count == 4,
              dateComponents[1].count == 2,
              dateComponents[2].count == 2
        else {
            return course.createdAt
        }

        return "\(dateComponents[0].suffix(2)).\(dateComponents[1]).\(dateComponents[2])"
    }
}

private struct MyPostReviewRow: View {
    let review: MyReviewItem
    let isMenuExpanded: Bool
    let menuTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(review.placeName)
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .trailing) {
                        Button(action: menuTapped) {
                            Image("ic_more_horizontal_circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .anchorPreference(key: RodiDropdownAnchorPreferenceKey.self, value: .bounds) {
                                    [AnyHashable("review-\(review.id)"): $0]
                                }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(isMenuExpanded ? "후기 메뉴 닫기" : "후기 메뉴 열기")
                    }

                Text(Self.dateFormatter.string(from: review.createdAt))
                    .font(.pretendard(size: 13, weight: .medium))
                    .tracking(-0.26)
                    .foregroundStyle(RodiColor.gray600)
            }

            Text(review.content)
                .font(.pretendard(size: 13, weight: .regular))
                .tracking(-0.26)
                .foregroundStyle(RodiColor.gray700)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .frame(height: 37)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RodiColor.gray200, lineWidth: 1)
                }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

private struct MyCoursesEmptyState: View {
    let filter: MyPostsReducer.CourseFilter
    let errorMessage: String?
    let retry: () -> Void
    let openCourseRegistration: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                Button(action: retry) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            } else {
                Image("img_my_courses_empty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 125, height: 50)

                Text(emptyTitle)
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray600)
                    .padding(.top, 16)

                if filter == .all {
                    Text("나만 알고 있는 운전 연습하기 좋은\n코스를 공유해보세요.")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Button(action: openCourseRegistration) {
                        Text("코스 등록하기")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RodiColor.primary, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.top, 16)
                    .accessibilityLabel("코스 등록하기")
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }

    private var emptyTitle: String {
        switch filter {
        case .all: "등록한 코스가 없어요!"
        case .approved: "승인된 코스가 없어요!"
        case .pending: "검토중인 코스가 없어요!"
        case .rejected: "반려된 코스가 없어요!"
        }
    }
}

private struct MyPostsEmptyState: View {
    let errorMessage: String?
    let retry: () -> Void
    let openPracticeRecords: () -> Void
    let hasPracticeRecords: Bool

    var body: some View {
        VStack(spacing: 8) {
            if let errorMessage {
                Text(errorMessage)
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                Button(action: retry) {
                    Text("다시 시도")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .center) {
                    Image("ic_review")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .padding(.bottom, 16)

                    Text("아직 작성한 후기가 없어요!")
                        .rodiTypography(.headline1)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.bottom, 8)

                    Text("다녀온 코스의 경험을 기록해보세요.")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)

                    if hasPracticeRecords {
                        Button(action: openPracticeRecords) {
                            Text("연습기록 보러가기")
                                .rodiTypography(.body3Medium)
                                .foregroundStyle(RodiColor.primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 7)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RodiColor.primary, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)
                        .accessibilityLabel("연습기록 보러가기")
                    }
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 104)
    }
}

private struct MyPostsRetryFooter: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)

            Button(action: retry) {
                Text("다시 시도")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct CourseDeleteConfirmationDialog: View {
    let isDeleting: Bool
    let errorMessage: String?
    let deleteAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("정말 삭제하시겠습니까?")
                            .font(.pretendard(size: 16, weight: .bold))
                            .tracking(-0.32)
                            .foregroundStyle(RodiColor.black)

                        Text("이 코스는 삭제하면 더 이상 공개되지 않아요.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)

                        if let errorMessage {
                            Text(errorMessage)
                                .rodiTypography(.caption2Medium)
                                .foregroundStyle(RodiColor.secondary400)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(minWidth: 240)

                    HStack(spacing: 8) {
                        Button(action: deleteAction) {
                            Group {
                                if isDeleting {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(RodiColor.gray800)
                                } else {
                                    Text("삭제하기")
                                        .rodiTypography(.buttonMedium)
                                        .foregroundStyle(RodiColor.gray800)
                                }
                            }
                            .frame(width: 116, height: 42)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(RodiColor.gray300, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)

                        Button(action: cancelAction) {
                            Text("취소")
                                .rodiTypography(.buttonMedium)
                                .foregroundStyle(RodiColor.white)
                                .frame(width: 116, height: 42)
                                .background(RodiColor.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(isDeleting)
                    }
                    .padding(.top, 24)
                }
            }
        }
    }
}
