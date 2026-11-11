import SwiftUI

struct CourseReportPage: View {
    @FocusState private var isDetailFocused: Bool

    let state: CourseReportReducer.State
    let send: (CourseReportReducer.Action) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                formContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: isDetailFocused) { isFocused in
                guard isFocused else { return }
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo("course-report-detail", anchor: .bottom) }
                }
            }
        }
        .background(RodiColor.white.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            RodiCenteredNavigationHeader(title: "신고하기") {
                Button {
                    send(.backTapped)
                } label: {
                    Image("ic_chevron_left_24")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(state.isSubmitting)
                .accessibilityLabel("코스 상세로 돌아가기")
            } trailing: {
                Color.clear.accessibilityHidden(true)
            }
            .background(RodiColor.white)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isDetailFocused {
                PrimaryBottomButton(
                    title: "제출",
                    isEnabled: state.submission != nil && !state.isSubmitting && !state.isCompletionPresented,
                    showsDivider: true
                ) { send(.submitTapped) }
            }
        }
        .overlay {
            if state.isCompletionPresented {
                CourseReportCompletionDialog { send(.completionConfirmed) }
                    .accessibilityAddTraits(.isModal)
            }
        }
    }
}

private extension CourseReportPage {
    @ViewBuilder
    var formContent: some View {
        switch state.formState {
        case .loading:
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, minHeight: 184)
                .accessibilityLabel("신고 사유를 불러오는 중")
        case .failed:
            VStack(spacing: 12) {
                Text("신고 사유를 불러오지 못했어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)
                RodiRetryButton { send(.retryTapped) }
            }
            .frame(maxWidth: .infinity, minHeight: 184)
        case .loaded(let form):
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(form.title)
                        .rodiTypography(.heading2)
                        .foregroundStyle(RodiColor.black)
                    if let description = form.description?.normalizedOptionalText {
                        Text(description)
                            .rodiTypography(.body3Medium)
                            .foregroundStyle(RodiColor.gray600)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(form.options) { option in
                        RodiRadioOption(title: option.label, isSelected: state.selectedCodes.contains(option.code)) {
                            isDetailFocused = false
                            send(.optionToggled(option.code))
                        }
                        if state.otherOption?.code == option.code {
                            detailField(for: option)
                                .padding(.top, 2)
                                .id("course-report-detail")
                        }
                    }
                }
                .disabled(state.isSubmitting || state.isCompletionPresented)
            }
        }
    }

    func detailField(for option: CourseReportForm.Option) -> some View {
        let count = state.detail.count
        let limit = state.detailLimit
        return VStack(alignment: .trailing, spacing: 4) {
            RodiTextField(
                text: Binding(get: { state.detail }, set: { send(.detailChanged($0)) }),
                placeholder: option.textInputPlaceholder ?? "이유를 작성해주세요.",
                characterLimit: limit,
                isFocused: $isDetailFocused
            )
            .padding(.vertical, 16)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isDetailFocused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .overlay {
                if !isDetailFocused {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isDetailFocused = true }
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(option.label)

            Text("\(count)/\(limit)")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
                .accessibilityLabel("\(limit)자 중 \(count)자 입력")
        }
    }
}
