import SwiftUI

struct CourseReviewReportPage: View {
    @FocusState private var isDetailFocused: Bool

    let state: CourseReviewReportReducer.State
    let send: (CourseReviewReportReducer.Action) -> Void

    var body: some View {
        ZStack {
            RodiColor.white
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    formContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .contentShape(Rectangle())
            .onTapGesture {
                isDetailFocused = false
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            submitBar
        }
        .overlay {
            if state.isCompletionPresented {
                completionDialog
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Layout
private extension CourseReviewReportPage {

    var header: some View {
        ZStack {
            Text("신고하기")
                .rodiTypography(.headline1)
                .foregroundStyle(RodiColor.black)

            HStack {
                Button {
                    send(.backTapped)
                } label: {
                    Image("ic_chevron_left_24")
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
                .disabled(isProcessingReport)
                .accessibilityLabel("이전 화면")

                Spacer()
            }
        }
        .frame(height: 56)
        .background(RodiColor.white)
    }

    @ViewBuilder
    var formContent: some View {
        switch state.formState {
        case .idle, .loading:
            ProgressView()
                .tint(RodiColor.primary)
                .frame(maxWidth: .infinity, minHeight: 184)
                .accessibilityLabel("신고 사유를 불러오는 중")

        case .loaded(let form):
            VStack(alignment: .leading, spacing: 0) {
                Text(form.title)
                    .rodiTypography(.heading2)
                    .foregroundStyle(RodiColor.black)

                if let description = form.description?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !description.isEmpty {
                    Text(description)
                        .rodiTypography(.body3Medium)
                        .foregroundStyle(RodiColor.gray600)
                        .padding(.top, 8)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(form.options) { option in
                        VStack(alignment: .leading, spacing: 4) {
                            RodiRadioOption(
                                title: option.label,
                                isSelected: state.selectedOption?.code == option.code,
                                action: { send(.optionSelected(option)) }
                            )

                            if state.selectedOption?.code == option.code,
                               option.requiresTextInput {
                                detailField(for: option)
                            }
                        }
                    }
                }
                .padding(.top, 24)
            }

        case .failed:
            VStack(spacing: 12) {
                Text("신고 사유를 불러오지 못했어요.")
                    .rodiTypography(.body3Medium)
                    .foregroundStyle(RodiColor.gray600)

                RodiRetryButton { send(.retryTapped) }
            }
            .frame(maxWidth: .infinity, minHeight: 184)
        }
    }

    func detailField(for option: ReviewReportOption) -> some View {
        VStack(spacing: 4) {
            RodiTextField(
                text: detailBinding,
                placeholder: option.textInputPlaceholder ?? "이유를 작성해주세요",
                characterLimit: state.maximumLength,
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
    }

    var submitBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(RodiColor.gray200)
                .frame(height: 1)

            Button {
                send(.submitTapped)
            } label: {
                Group {
                    if isProcessingReport {
                        ProgressView()
                            .tint(RodiColor.white)
                            .controlSize(.small)
                    } else {
                        Text("제출")
                            .rodiTypography(.buttonMedium)
                    }
                }
                .foregroundStyle(isSubmitEnabled ? RodiColor.white : RodiColor.gray500)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isSubmitEnabled ? RodiColor.primary : RodiColor.gray300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!isSubmitEnabled)
            .accessibilityLabel("신고 제출")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(RodiColor.white)
    }

    var completionDialog: some View {
        RodiModalBackground {
            RodiDialog(contentInsets: .init(top: 32, leading: 20, bottom: 32, trailing: 20)) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        Text("신고가 접수되었습니다.")
                            .rodiTypography(.body1SemiBold)
                            .foregroundStyle(RodiColor.black)

                        Text("관리자의 검토 후 빠른 시일내에\n조치 예정입니다.")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.black)
                            .multilineTextAlignment(.center)
                            .frame(height: 60)
                    }
                    .frame(minWidth: 240)

                    Button {
                        send(.completionConfirmed)
                    } label: {
                        Text("확인")
                            .rodiTypography(.buttonMedium)
                            .foregroundStyle(RodiColor.white)
                            .frame(width: 116, height: 42)
                            .background(RodiColor.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 24)
                    .accessibilityLabel("신고 완료 확인")
                }
            }
        }
    }

    var detailBinding: Binding<String> {
        Binding(
            get: { state.detail },
            set: { send(.detailChanged($0)) }
        )
    }

    var isProcessingReport: Bool {
        state.isSubmitting
    }

    var isSubmitEnabled: Bool {
        state.canSubmit && !isProcessingReport
    }
}
