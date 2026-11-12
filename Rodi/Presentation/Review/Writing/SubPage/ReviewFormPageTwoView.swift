import SwiftUI

struct ReviewFormPageTwoView: View {
    let state: ReviewWritingReducer.State
    let send: (ReviewWritingReducer.Action) -> Void

    @State private var isContentFocused = false

    var body: some View {
        ReviewFormScaffold(
            header: ReviewFormHeader(
                title: state.form?.title ?? "후기 남기기",
                showsBack: true,
                backAction: { send(.backTapped) },
                closeAction: { send(.closeTapped) }
            ),
            ignoresKeyboardSafeArea: true
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(state.form?[.practiceMethod]?.title ?? "연습 방법")
                        .rodiTypography(.body1SemiBold)
                        .foregroundStyle(RodiColor.black)

                    HStack(spacing: 6) {
                        if let options = state.form?[.practiceMethod]?.options {
                            ForEach(options) { option in
                                if let method = ReviewPracticeMethod(rawValue: option.code) {
                                    methodButton(method, title: option.label)
                                }
                            }
                        } else {
                            methodButton(.solo, title: ReviewPracticeMethod.solo.title)
                            methodButton(.accompanied, title: ReviewPracticeMethod.accompanied.title)
                        }
                    }
                    .padding(.top, 12)

                    if state.form == nil || state.form?[.content]?.isVisible(for: state.draft.isRecommended) == true {
                        Text(state.form?[.content]?.title ?? "후기 작성")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)
                            .padding(.top, 40)

                        reviewTextEditor

                        Text("\(state.draft.content.count) / \(state.contentLimit)")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray600)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.top, 4)
                    }

                    Color.clear
                        .frame(height: 48)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: dismissContentKeyboard)
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture(perform: dismissContentKeyboard)
        } bottomBar: {
            PrimaryBottomButton(
                title: "완료",
                isEnabled: state.canSubmit,
                showsDivider: true,
                action: { send(.submitTapped) }
            )
        }
    }
}

// MARK: - Component
private extension ReviewFormPageTwoView {

    var reviewTextEditor: some View {
        ReviewTextEditor(
            text: contentBinding,
            characterLimit: state.contentLimit,
            isFocused: $isContentFocused
        )
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isContentFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                if state.draft.content.isEmpty {
                    Text(state.form == nil ? "자유롭게 후기를 작성해주세요." : state.form?[.content]?.placeholder ?? "")
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray500)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.top, 12)
    }

    func methodButton(_ method: ReviewPracticeMethod, title: String) -> some View {
        ReviewChoiceButton(title: title, isSelected: state.draft.practiceMethod == method) {
            send(.practiceMethodSelected(method))
        }
    }

    var contentBinding: Binding<String> {
        Binding(
            get: { state.draft.content },
            set: { send(.contentChanged($0)) }
        )
    }

    func dismissContentKeyboard() {
        isContentFocused = false
    }
}
