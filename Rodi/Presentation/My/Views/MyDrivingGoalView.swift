//
//  MyDrivingGoalView.swift
//  Rodi
//

import SwiftUI

struct MyDrivingGoalView: View {
    private enum Metrics {
        static let characterLimit = 30
    }

    let memberRepository: MemberRepository
    let onUpdated: (MemberProfile) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var drivingGoal: String
    @State private var isFieldFocused = false
    @State private var isSaving = false
    @State private var errorToastMessage: String?

    init(
        initialDrivingGoal: String,
        memberRepository: MemberRepository,
        onUpdated: @escaping (MemberProfile) -> Void
    ) {
        self.memberRepository = memberRepository
        self.onUpdated = onUpdated
        _drivingGoal = State(initialValue: initialDrivingGoal)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("이루고 싶은 운전 목표를 입력해주세요.")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                    .padding(.bottom, 12)

                OnboardingLimitedTextField(
                    text: $drivingGoal,
                    placeholder: "ex)강남 운전 자신있게 하기!",
                    characterLimit: Metrics.characterLimit,
                    isFocused: $isFieldFocused
                )
                .frame(height: 20)
                .padding(.vertical, 16)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFieldFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                }

                Text("\(drivingGoal.count) / \(Metrics.characterLimit)")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            Spacer()
        }
        .background(RodiColor.white)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let errorToastMessage {
                MyDrivingGoalErrorToast(message: errorToastMessage)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: errorToastMessage)
    }

    private var header: some View {
        ZStack {
            Text("운전 목표")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(RodiColor.black)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")

                Spacer()

                Button(action: saveDrivingGoal) {
                    Circle()
                        .fill(canSave ? RodiColor.primary : RodiColor.primary100)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if isSaving {
                                ProgressView()
                                    .tint(RodiColor.white)
                                    .scaleEffect(0.65)
                            } else {
                                Image(canSave ? "ic_driving_goal_check_active" : "ic_driving_goal_check_inactive")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canSave || isSaving)
                .accessibilityLabel("운전 목표 저장")
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 16)
    }

    private var canSave: Bool {
        drivingGoal.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    private func saveDrivingGoal() {
        guard canSave, !isSaving else { return }

        isSaving = true
        isFieldFocused = false

        Task {
            do {
                let normalizedGoal = drivingGoal.trimmingCharacters(in: .whitespacesAndNewlines)
                try await memberRepository.updateDrivingGoal(normalizedGoal)
                let updatedProfile = try await memberRepository.fetchMyProfile()
                onUpdated(updatedProfile)
                dismiss()
            } catch {
                showErrorToast()
            }
            isSaving = false
        }
    }

    private func showErrorToast() {
        let message = "작성해주신 목표가 정상적으로 처리되지 못했어요.\n다시 한번 시도해주세요."
        errorToastMessage = message

        Task {
            try? await Task.sleep(for: .seconds(3))
            guard errorToastMessage == message else { return }
            errorToastMessage = nil
        }
    }
}

private struct MyDrivingGoalErrorToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(RodiColor.white)
                .frame(width: 24, height: 24)

            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.white)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
        .background(RodiColor.gray800)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
