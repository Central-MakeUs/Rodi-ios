import SwiftUI

struct ReviewFormPageOneView: View {
    private enum ScrollTarget {
        case cautionKeyboardAnchor
    }

    let state: ReviewWritingReducer.State
    let send: (ReviewWritingReducer.Action) -> Void

    @FocusState private var isCautionFocused: Bool

    var body: some View {
        ReviewFormScaffold(
            header: ReviewFormHeader(
                title: state.form?.title ?? "후기 남기기",
                showsBack: false,
                closeAction: { send(.closeTapped) }
            ),
            ignoresKeyboardSafeArea: false,
            bottomSafeAreaInset: isCautionFocused ? 0 : nil
        ) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        title
                            .padding(.top, 28)

                        recommendationSection

                        if state.form == nil || state.draft.isRecommended == true {
                            ReviewScaleSelector(
                                title: state.form?[.difficulty]?.title ?? "난이도",
                                selected: state.draft.difficulty,
                                serverOptions: state.form?[.difficulty]?.options.compactMap { option in
                                    ReviewDifficulty(rawValue: option.code).map { ($0, option.label) }
                                },
                                action: { send(.difficultySelected($0)) }
                            )

                            ReviewScaleSelector(
                                title: state.form?[.congestion]?.title ?? "혼잡도",
                                selected: state.draft.congestion,
                                serverOptions: state.form?[.congestion]?.options.compactMap { option in
                                    ReviewCongestion(rawValue: option.code).map { ($0, option.label) }
                                },
                                action: { send(.congestionSelected($0)) }
                            )
                        }

                        VStack(spacing: 0) {
                            if state.form == nil ||
                                (state.draft.isRecommended == true && state.form?[.caution]?.isVisible(for: true) == true) {
                                inputSection(
                                    title: state.form?[.caution]?.title ?? "주의사항",
                                    text: Binding(get: { state.draft.caution }, set: { send(.cautionChanged($0)) }),
                                    placeholder: state.form == nil ? "예) 갑자기 나오는 자전거 주의!" : state.form?[.caution]?.placeholder ?? "",
                                    limit: state.form?[.caution]?.maxLength
                                )
                            } else if state.draft.isRecommended == false, let issues = state.form?[.courseIssues] {
                                issueSection(issues)
                            }

                            Color.clear
                                .frame(height: isCautionFocused ? 48 : 24)
                                .id(ScrollTarget.cautionKeyboardAnchor)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture(perform: dismissCautionKeyboard)
                .onChange(of: isCautionFocused) { isFocused in
                    guard isFocused else { return }

                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(ScrollTarget.cautionKeyboardAnchor, anchor: .bottom)
                        }
                    }
                }
            }
        } bottomBar: {
            if !isCautionFocused {
                PrimaryBottomButton(
                    title: "다음",
                    isEnabled: state.canProceedToSecondPage,
                    showsDivider: true,
                    action: { send(.nextTapped) }
                )
            }
        }
    }
}

// MARK: - Section
private extension ReviewFormPageOneView {

    @ViewBuilder
    var title: some View {
        let placeName = state.target?.placeName ?? ""
        let heading = state.form?.firstStepTitle ?? "\(placeName)의\n연습은 어땠나요?"
        if !placeName.isEmpty, let match = heading.range(of: placeName) {
            (Text(String(heading[..<match.lowerBound])).foregroundColor(RodiColor.black)
             + Text(placeName).foregroundColor(RodiColor.primary)
             + Text(String(heading[match.upperBound...])).foregroundColor(RodiColor.black))
                .rodiTypography(.heading2)
        } else {
            Text(heading)
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)
        }
    }

    var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(state.form?[.isRecommended]?.title ?? "이 코스를 다른 초보 운전자에게 추천하시겠어요?")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            HStack(spacing: 6) {
                if let options = state.form?[.isRecommended]?.options {
                    ForEach(options) { option in
                        recommendationButton(option.label, value: option.code == "true")
                    }
                } else {
                    recommendationButton("별로예요", value: false)
                    recommendationButton("추천해요", value: true)
                }
            }
        }
    }

    func recommendationButton(_ title: String, value: Bool) -> some View {
        ReviewChoiceButton(title: title, isSelected: state.draft.isRecommended == value) {
            dismissCautionKeyboard()
            send(.recommendationSelected(value))
        }
    }

    func issueSection(_ question: ReviewWritingForm.Question) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            VStack(spacing: 0) {
                ForEach(question.options) { option in
                    RodiRadioOption(
                        title: option.label,
                        isSelected: state.draft.courseIssues.contains(option.code),
                        labelTypography: .body3Medium
                    ) {
                        dismissCautionKeyboard()
                        send(.courseIssueToggled(option.code))
                    }

                    if state.issueTextOption?.code == option.code {
                        issueDetailField(for: option)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }

    func issueDetailField(for option: ReviewWritingForm.Option) -> some View {
        let limit = min(option.textInputMaxLength ?? 30, 30)
        let count = state.draft.courseIssueDetail.count

        return VStack(alignment: .trailing, spacing: 4) {
            inputField(
                text: Binding(get: { state.draft.courseIssueDetail }, set: { send(.courseIssueDetailChanged($0)) }),
                placeholder: option.textInputPlaceholder ?? "",
                limit: limit,
                verticalPadding: 16
            )
            .accessibilityLabel(option.label)

            Text("\(count)/\(limit)")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
                .accessibilityLabel("\(limit)자 중 \(count)자 입력")
        }
    }

    func inputSection(title: String, text: Binding<String>, placeholder: String, limit: Int?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            inputField(text: text, placeholder: placeholder, limit: limit, verticalPadding: 14)
        }
    }

    func inputField(text: Binding<String>, placeholder: String, limit: Int?, verticalPadding: CGFloat) -> some View {
        RodiTextField(
            text: text,
            placeholder: placeholder,
            characterLimit: limit,
            isFocused: $isCautionFocused
        )
        .padding(.vertical, verticalPadding)
        .background(RodiColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCautionFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
        }
        .overlay {
            if !isCautionFocused {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isCautionFocused = true
                    }
            }
        }
    }

    func dismissCautionKeyboard() {
        isCautionFocused = false
    }
}
