import SwiftUI

struct ReviewSkipReasonView: View {
    private static let detailFieldID = "review-skip-reason-detail"

    let state: ReviewSkipReasonReducer.State
    let send: (ReviewSkipReasonReducer.Action) -> Void

    @FocusState private var isDetailFocused: Bool

    var body: some View {
        ReviewFormScaffold(
            header: ReviewFormHeader(
                title: "미방문 사유",
                showsBack: false,
                closeAction: { send(.closeTapped) }
            ),
            ignoresKeyboardSafeArea: false,
            bottomSafeAreaInset: isDetailFocused ? 0 : nil
        ) {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("왜 연습을 다녀오지 않았나요?")
                            .rodiTypography(.heading2)
                            .foregroundStyle(RodiColor.black)

                        Text("이유를 알려주시면 더 나은 코스를 추천해드릴게요!")
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray600)
                            .padding(.top, 8)

                        formContent
                            .padding(.top, 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture(perform: dismissDetailKeyboard)
                .onChange(of: isDetailFocused) { isFocused in
                    guard isFocused else { return }

                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo(Self.detailFieldID, anchor: .bottom)
                        }
                    }
                }
            }
        } bottomBar: {
            if !isDetailFocused {
                PrimaryBottomButton(
                    title: "완료",
                    isEnabled: state.canSubmit,
                    showsDivider: true,
                    action: { send(.submitTapped) }
                )
            }
        }
    }
}

// MARK: - Content
private extension ReviewSkipReasonView {

    @ViewBuilder
    var formContent: some View {
        switch state.formState {
        case .idle, .loading:
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, minHeight: 184)

        case .loaded(let form):
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(form.options) { option in
                        RodiRadioOption(
                            title: option.label,
                            isSelected: state.selectedReason?.code == option.code,
                            action: { send(.reasonSelected(option)) }
                        )
                    }
                }

                if let selectedReason = state.selectedReason,
                   selectedReason.requiresTextInput {
                    detailField(for: selectedReason)
                        .padding(.top, 4)
                        .id(Self.detailFieldID)
                }
            }

        case .failed:
            VStack(spacing: 12) {
                Text("미방문 사유를 불러오지 못했어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton { send(.retryTapped) }
            }
            .frame(maxWidth: .infinity, minHeight: 184)
        }
    }

    func detailField(for option: PracticeSkipReasonOption) -> some View {
        VStack(spacing: 4) {
            RodiTextField(
                text: detailBinding,
                placeholder: option.textInputPlaceholder ?? "이유를 작성해주세요",
                characterLimit: state.detailCharacterLimit,
                isFocused: $isDetailFocused
            )
            .padding(.vertical, 14)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isDetailFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
            }
        }
        .padding(.bottom, 48)
    }

    var detailBinding: Binding<String> {
        Binding(
            get: { state.detail },
            set: { send(.detailChanged($0)) }
        )
    }

    func dismissDetailKeyboard() {
        isDetailFocused = false
    }
}
