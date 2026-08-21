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
                title: "후기 남기기",
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

                        ReviewScaleSelector(
                            title: "난이도",
                            selected: state.draft.difficulty,
                            action: { send(.difficultySelected($0)) }
                        )

                        ReviewScaleSelector(
                            title: "혼잡도",
                            selected: state.draft.congestion,
                            action: { send(.congestionSelected($0)) }
                        )

                        VStack(spacing: 0) {
                            cautionSection(proxy: proxy)

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

    var title: some View {
        (
            Text(state.target?.placeName ?? "")
                .foregroundColor(RodiColor.primary)
            + Text("의\n연습은 어땠나요?")
                .foregroundColor(RodiColor.black)
        )
        .rodiTypography(.heading2)
    }

    var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이 코스를 다른 초보 운전자에게 추천하시겠어요?")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            HStack(spacing: 6) {
                ReviewChoiceButton(title: "별로예요", isSelected: state.draft.isRecommended == false) {
                    send(.recommendationSelected(false))
                }
                ReviewChoiceButton(title: "추천해요", isSelected: state.draft.isRecommended == true) {
                    send(.recommendationSelected(true))
                }
            }
        }
    }

    func cautionSection(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주의사항")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            RodiTextField(
                text: Binding(get: { state.draft.caution }, set: { send(.cautionChanged($0)) }),
                placeholder: "예) 갑자기 나오는 자전거 주의!",
                characterLimit: nil,
                isFocused: $isCautionFocused
            )
            .padding(.vertical, 14)
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
                            focusCautionField(using: proxy)
                        }
                }
            }
        }
    }

    func focusCautionField(using proxy: ScrollViewProxy) {
        guard !isCautionFocused else { return }

        isCautionFocused = true
    }

    func dismissCautionKeyboard() {
        isCautionFocused = false
    }
}
