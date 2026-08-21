//
//  DebugFeatureTestPage.swift
//  Rodi
//

#if DEBUG
import SwiftUI

struct DebugFeatureTestPage: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLiveActivityTestPickerPresented = false
    @State private var isMyCoursesPreviewPresented = false
    @State private var isHardWithdrawalConfirmationPresented = false
    @State private var isMandatoryUpdateTestPresented = false
    @State private var isHardWithdrawalSubmitting = false
    @State private var hardWithdrawalErrorMessage: String?

    let reviewPromptAction: () -> Void
    let hardWithdrawAction: () async throws -> Void

    init(
        reviewPromptAction: @escaping () -> Void,
        hardWithdrawAction: @escaping () async throws -> Void
    ) {
        self.reviewPromptAction = reviewPromptAction
        self.hardWithdrawAction = hardWithdrawAction
    }

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
