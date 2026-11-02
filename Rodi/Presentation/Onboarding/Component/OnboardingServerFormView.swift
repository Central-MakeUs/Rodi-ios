import SwiftUI

struct OnboardingServerFormView: View {
    let state: OnboardingProfileReducer.State
    let send: (OnboardingProfileReducer.Action) -> Void
    @FocusState private var isGoalFocused: Bool

    private var isExperience: Bool { state.screen == .drivingExperience }

    var body: some View {
        if isExperience {
            VStack(spacing: 0) { fields; actions }
        } else {
            ZStack(alignment: .bottom) {
                fields
                actions.opacity(isGoalFocused ? 0 : 1)
                    .allowsHitTesting(!isGoalFocused)
                    .accessibilityHidden(isGoalFocused)
            }
        }
    }

    private var fields: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    if let step = state.formStep {
                        VStack(alignment: .leading, spacing: 8) {
                            if let title = step.title { Text(title).rodiTypography(.heading2).foregroundStyle(RodiColor.black) }
                            if let description = step.description { Text(description).rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600) }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 32) {
                        ForEach(state.visibleQuestions) { question in
                            questionContent(question, proxy: proxy)
                                .id(question.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, isGoalFocused ? 24 : (isExperience ? 24 : 80))
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if !isExperience, state.formStep?.skippable == true {
            DualBottomButton(
                secondaryTitle: "건너뛰기", primaryTitle: "다음", isPrimaryEnabled: state.canProceedFromForm,
                secondaryAction: { send(.preferenceSkipTapped) }, primaryAction: { send(.preferenceNextTapped) }
            )
        } else {
            PrimaryBottomButton(title: "다음", isEnabled: state.canProceedFromForm, showsDivider: true) {
                send(isExperience ? .drivingExperienceNextTapped : .preferenceNextTapped)
            }
        }
    }

    private func questionContent(_ question: MemberOnboardingForm.Question, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(question.title).rodiTypography(.body1SemiBold).foregroundStyle(RodiColor.black)
                if question.kind == .ranked, let limit = question.maxSelect {
                    Text("최대 \(limit)개").rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600)
                } else if question.kind == .multiple {
                    Text("복수선택").rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600)
                }
            }
            if let description = question.description {
                Text(description).rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600).padding(.top, 10)
            }
            if question.kind == .text {
                goalField(question, proxy: proxy).padding(.top, 12)
            } else if question.id == .carType {
                // 기존 차종 칩의 두 줄 배치를 서버의 표시 순서에 적용합니다.
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) { ForEach(Array(question.options.prefix(4))) { option in chip(option, question: question) } }
                    if question.options.count > 4 {
                        HStack(spacing: 6) { ForEach(Array(question.options.dropFirst(4))) { option in chip(option, question: question) } }
                    }
                }.padding(.top, 12)
            } else {
                RodiChipFlow {
                    ForEach(question.options) { option in chip(option, question: question) }
                }.padding(.top, question.kind == .ranked ? 8 : 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ option: MemberOnboardingForm.Option, question: MemberOnboardingForm.Question) -> some View {
        let index = state.formAnswers[question.id]?.firstIndex(of: option.id)
        return RodiSelectionChip(
            title: option.label, isSelected: index != nil,
            selectionOrder: question.kind == .ranked ? index.map { $0 + 1 } : nil,
            action: {
                isGoalFocused = false
                send(.selectFormOption(question.id, option.id))
            }
        )
    }

    private func goalField(_ question: MemberOnboardingForm.Question, proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            RodiTextField(
                text: Binding(get: { state.drivingGoal }, set: { send(.drivingGoalChanged($0)) }),
                placeholder: question.placeholder ?? "", characterLimit: question.maxLength, isFocused: $isGoalFocused
            )
            .padding(.vertical, 16)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).stroke(isGoalFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1) }
            .overlay {
                if !isGoalFocused {
                    Color.clear.contentShape(Rectangle()).onTapGesture {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) { proxy.scrollTo(question.id, anchor: .bottom) }
                        isGoalFocused = true
                    }
                }
            }
            Text(question.maxLength.map { "\(state.drivingGoal.count)/\($0)" } ?? "\(state.drivingGoal.count)")
                .rodiTypography(.body3Medium).foregroundStyle(RodiColor.gray600)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
