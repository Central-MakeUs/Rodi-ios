//
//  PlaceListView.swift
//  Rodi
//

import SwiftUI

/// 현재 지도 뷰포트 안의 장소 목록을 커서 페이지 단위로 표시한다.
struct PlaceListView: View {
    let items: [PlaceListItem]
    let isInitialLoading: Bool
    let isAwaitingRegionViewport: Bool
    let isNextPageLoading: Bool
    let errorMessage: String?
    let hasNextPage: Bool
    let isExpanded: Bool
    let selectAction: (PlaceListItem) -> Void
    let reloadAction: () -> Void
    let loadNextPageAction: () -> Void
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: @MainActor () async throws -> Void

    var body: some View {
        Group {
            if items.isEmpty, isInitialLoading || isAwaitingRegionViewport {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if items.isEmpty, let errorMessage {
                PlaceListMessageView(message: errorMessage, actionTitle: "다시 시도", action: reloadAction)
            } else if items.isEmpty {
                PlaceListEmptyResultView(
                    isExpanded: isExpanded,
                    debugReviewTestAction: debugReviewTestAction,
                    debugHardWithdrawAction: debugHardWithdrawAction
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { item in
                            PlaceListItemCard(item: item, selectAction: selectAction)

                            if item.id != items.last?.id {
                                Rectangle()
                                    .fill(RodiColor.primaryMinus100)
                                    .frame(height: 2)
                                    .padding(.horizontal, 16)
                            }
                        }

                        if hasNextPage {
                            Color.clear
                                .frame(height: 1)
                                .onAppear(perform: loadNextPageAction)
                        }

                        if isNextPageLoading {
                            ProgressView()
                                .padding(.vertical, 20)
                        }

                        if let errorMessage {
                            PlaceListMessageView(
                                message: errorMessage,
                                actionTitle: "다시 시도",
                                action: loadNextPageAction
                            )
                            .padding(.vertical, 16)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// 홈 추천 목록과 마이 저장 목록에서 공유하는 장소 카드입니다.
struct PlaceListItemCard: View {
    let item: PlaceListItem
    var selectAction: ((PlaceListItem) -> Void)?

    var body: some View {
        Group {
            if let selectAction {
                Button {
                    selectAction(item)
                } label: {
                    cardContent
                }
            } else {
                cardContent
            }
        }
        .buttonStyle(.plain)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch item.type {
            case .course:
                courseContent
            case .parking:
                parkingContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var courseContent: some View {
        Group {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if let distanceMeters = item.distanceMeters {
                    HStack(spacing: 2) {
                        Text(courseDistanceText(distanceMeters))
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.primary)
                        Text("주행거리")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray700)
                    }
                    .fixedSize()
                }
            }

            if !item.practiceTypes.isEmpty {
                PlaceListTagRow(tags: item.practiceTypes)
            }

            if let summary = item.summary?.trimmingCharacters(in: .whitespacesAndNewlines), !summary.isEmpty {
                Text(summary)
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RodiColor.gray50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var parkingContent: some View {
        Group {
            Text(item.name)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
                .lineLimit(1)

            Text(item.address)
                .rodiTypography(.caption1Medium)
                .foregroundStyle(RodiColor.gray700)
                .lineLimit(1)

            PlaceListParkingMetaRow(openTime: item.openTime)

            if let capacity = item.capacity {
                Text("총 주차 면수 · \(capacity.formatted())대")
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray700)
            }
        }
    }

    private func courseDistanceText(_ meters: Int) -> String {
        if meters >= 1_000 {
            let kilometers = Double(meters) / 1_000
            return kilometers.rounded() == kilometers
                ? "\(Int(kilometers))km"
                : "\(String(format: "%.1f", kilometers))km"
        }

        return "\(meters)m"
    }
}

private struct PlaceListParkingMetaRow: View {
    let openTime: String?

    private var normalizedOpenTime: String? {
        guard let openTime else { return nil }
        let value = openTime.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var body: some View {
        HStack(spacing: 4) {
            PlaceListTagRow(tags: [PlacePracticeType.parking.rawValue])

            if let normalizedOpenTime {
                Text("･")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray800)

                HStack(spacing: 0) {
                    Text(normalizedOpenTime)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                    Text("에 영업 시작")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray800)
                }
                .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1)
    }
}

private struct PlaceListTagRow: View {
    let tags: [String]

    private var displayTags: [String] {
        tags.map(PlacePracticeType.displayName(for:))
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(displayTags.prefix(3)), id: \.self) { tag in
                Text(tag)
                    .rodiTypography(.caption1Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RodiColor.gray200)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
            }
        }
    }
}

private struct PlaceListMessageView: View {
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray700)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }
}

private struct PlaceListEmptyResultView: View {
    let isExpanded: Bool
    let debugReviewTestAction: () -> Void
    let debugHardWithdrawAction: @MainActor () async throws -> Void

    #if DEBUG
    @State private var isDebugTestPagePresented = false
    #endif

    var body: some View {
        #if DEBUG
        layout
            .fullScreenCover(isPresented: $isDebugTestPagePresented) {
                DebugFeatureTestPage(
                    reviewPromptAction: debugReviewTestAction,
                    hardWithdrawAction: debugHardWithdrawAction
                )
            }
        #else
        layout
        #endif
    }

    private var layout: some View {
        Group {
            if isExpanded {
                VStack {
                    Spacer(minLength: 0)
                    emptyContent
                    Spacer(minLength: 0)
                }
                .padding(.bottom, 56)
            } else {
                VStack {
                    emptyContent
                    Spacer(minLength: 0)
                }
                .padding(.top, 68)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : nil)
    }

    private var emptyContent: some View {
        VStack(spacing: 16) {
            emptyImage

            VStack(spacing: 8) {
                Text("추천할 수 있는 연습 코스를 찾지 못했어요.")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)

                Text("지도를 축소시켜, 전체 지역의\n연습 코스를 둘러보세요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var emptyImage: some View {
        Image("img_empty_radius_result")
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            #if DEBUG
            .onTapGesture(count: 3) {
                isDebugTestPagePresented = true
            }
            .accessibilityHint("개발용 기능 테스트 페이지를 열려면 세 번 탭하세요.")
            #endif
    }
}

#if DEBUG
private struct DebugFeatureTestPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLiveActivityTestPickerPresented = false
    @State private var isMyCoursesPreviewPresented = false
    @State private var isHardWithdrawalConfirmationPresented = false
    @State private var isMandatoryUpdateTestPresented = false
    @State private var isHardWithdrawalSubmitting = false
    @State private var hardWithdrawalErrorMessage: String?

    let reviewPromptAction: () -> Void
    let hardWithdrawAction: @MainActor () async throws -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("테스트")
                    .rodiTypography(.headline1)
                    .foregroundStyle(RodiColor.black)

                Spacer()

                Button(action: dismiss.callAsFunction) {
                    Image("ic_close")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(RodiColor.gray700)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("테스트 페이지 닫기")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            VStack(spacing: 12) {
                testButton(title: "Live Activity") {
                    isLiveActivityTestPickerPresented = true
                }
                testButton(title: "후기등록 팝업") {
                    reviewPromptAction()
                    dismiss()
                }
                testButton(title: "등록한 코스") {
                    isMyCoursesPreviewPresented = true
                }
                testButton(title: "즉시 탈퇴 API") {
                    isHardWithdrawalConfirmationPresented = true
                }
                testButton(title: "강제 업데이트 알림") {
                    isMandatoryUpdateTestPresented = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)

            Spacer()
        }
        .background(RodiColor.white.ignoresSafeArea())
        .confirmationDialog(
            "Live Activity 테스트",
            isPresented: $isLiveActivityTestPickerPresented,
            titleVisibility: .visible
        ) {
            Button("연습 코스로 이동중") {
                PracticeLiveActivityService.shared.showPreview(state: .headingToCourse)
            }
            Button("코스 주행중") {
                PracticeLiveActivityService.shared.showPreview(state: .drivingCourse)
            }
            Button("코스 주행중 - 방금 출발") {
                PracticeLiveActivityService.shared.showPreview(state: .drivingCourseJustStarted)
            }
            Button("코스 주행 완료") {
                PracticeLiveActivityService.shared.showPreview(state: .completed)
            }
            Button("취소", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isMyCoursesPreviewPresented) {
            DebugMyCoursesPreviewPage()
        }
        .overlay {
            ZStack {
                if isHardWithdrawalConfirmationPresented {
                    DebugHardWithdrawalConfirmationDialog(
                        isSubmitting: isHardWithdrawalSubmitting,
                        confirmAction: requestHardWithdrawal,
                        cancelAction: {
                            guard !isHardWithdrawalSubmitting else { return }
                            isHardWithdrawalConfirmationPresented = false
                        }
                    )
                }

                if isMandatoryUpdateTestPresented {
                    RodiMandatoryUpdateDialog {
                        isMandatoryUpdateTestPresented = false
                    }
                }
            }
        }
        .rodiSnackbar(message: hardWithdrawalErrorMessage)
        .task(id: hardWithdrawalErrorMessage) {
            guard hardWithdrawalErrorMessage != nil else { return }
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            hardWithdrawalErrorMessage = nil
        }
    }

    private func testButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(RodiColor.gray100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func requestHardWithdrawal() {
        guard !isHardWithdrawalSubmitting else { return }
        isHardWithdrawalSubmitting = true
        Task { @MainActor in
            do {
                try await hardWithdrawAction()
                isHardWithdrawalSubmitting = false
                isHardWithdrawalConfirmationPresented = false
                dismiss()
            } catch {
                isHardWithdrawalSubmitting = false
                hardWithdrawalErrorMessage = "즉시 탈퇴를 처리하지 못했어요. 잠시 후 다시 시도해주세요."
            }
        }
    }
}

private struct DebugHardWithdrawalConfirmationDialog: View {
    let isSubmitting: Bool
    let confirmAction: () -> Void
    let cancelAction: () -> Void

    var body: some View {
        RodiModalBackground {
            RodiDialog {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("정말 삭제하시겠습니까?")
                            .rodiTypography(.headline1)
                            .foregroundStyle(RodiColor.black)

                        Text("즉시 탈퇴한 계정은 복구할 수 없어요.")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray700)
                    }
                    .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Button(action: cancelAction) {
                            Text("취소")
                                .rodiTypography(.buttonMedium)
                                .foregroundStyle(RodiColor.gray700)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RodiColor.gray300, lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)

                        Button(action: confirmAction) {
                            Group {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(RodiColor.white)
                                } else {
                                    Text("확인")
                                        .rodiTypography(.buttonMedium)
                                }
                            }
                            .foregroundStyle(RodiColor.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(isSubmitting)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct DebugMyCoursesPreviewPage: View {
    @Environment(\.dismiss) private var dismiss

    private let sampleCourses: [MyCourseItem] = [
        .init(id: 1, name: "서울 성북구 길음동 4938-3", approvalStatus: .approved, createdAt: "2026-05-10T09:00:00"),
        .init(id: 2, name: "서울 강남구 압구정로 123", approvalStatus: .pending, createdAt: "2026-05-09T09:00:00"),
        .init(id: 3, name: "서울 마포구 월드컵로 240", approvalStatus: .rejected, createdAt: "2026-05-08T09:00:00")
    ]

    var body: some View {
        VStack(spacing: 0) {
            MySubpageHeader(title: "내 활동", backAction: dismiss.callAsFunction)
            testTabBar

            HStack {
                Spacer()
                HStack(spacing: 2) {
                    Text("전체")
                        .rodiTypography(.body3Medium)
                    Image("ic_chevron_down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                .foregroundStyle(RodiColor.gray700)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(sampleCourses) { course in
                        VStack(alignment: .leading, spacing: 24) {
                            DebugMyCourseRow(course: course)
                            Rectangle()
                                .fill(RodiColor.primaryMinus100)
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var testTabBar: some View {
        HStack(spacing: 0) {
            Text("등록한 코스")
                .font(.pretendard(size: 16, weight: .semibold))
                .tracking(-0.32)
                .foregroundStyle(RodiColor.black)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .overlay(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(RodiColor.black)
                        .frame(height: 2)
                }

            Text("작성한 후기")
                .font(.pretendard(size: 16, weight: .medium))
                .tracking(-0.32)
                .foregroundStyle(RodiColor.gray400)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RodiColor.gray200)
                .frame(height: 1)
        }
    }
}

private struct DebugMyCourseRow: View {
    let course: MyCourseItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(course.name)
                    .font(.pretendard(size: 15, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(RodiColor.black)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image("ic_more_horizontal_circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
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
        guard dateComponents.count == 3 else { return course.createdAt }
        return "\(dateComponents[0].suffix(2)).\(dateComponents[1]).\(dateComponents[2])"
    }
}
#endif
