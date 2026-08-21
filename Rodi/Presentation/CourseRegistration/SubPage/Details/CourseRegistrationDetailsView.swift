import SwiftUI

struct CourseRegistrationDetailsView: View {
    private enum ScrollTarget: Hashable {
        case cautionKeyboardAnchor
        case descriptionKeyboardAnchor
    }

    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets
    @FocusState private var isCautionFocused: Bool
    @FocusState private var isDescriptionFocused: Bool

    let state: CourseRegistrationDetailsReducer.State
    let send: (CourseRegistrationDetailsReducer.Action) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CourseRegistrationHeader(title: "코스 등록", closeAction: { send(.backTapped) })
                .background(RodiColor.white)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, screenSafeAreaInsets.top)
        .padding(.bottom, isTextFieldFocused ? 0 : screenSafeAreaInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RodiColor.white)
        .onDisappear { send(.deactivated) }
        .ignoresSafeArea(.container)
        .ignoresSafeArea([], edges: .bottom)
        .overlay(alignment: .bottom) {
            if let alertToast = state.alertToast {
                CourseRegistrationAlertToast(message: alertToast.message)
                    .padding(.horizontal, 16)
                    .padding(.bottom, isTextFieldFocused ? 24 : 96)
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if state.isDiscardConfirmationPresented {
                ReviewDiscardConfirmationView(
                    send: { action in
                        switch action {
                        case .discard: send(.discardConfirmed)
                        case .keepWriting: send(.discardCancelled)
                        }
                    },
                    confirmAction: ConfirmationAction.discard,
                    cancelAction: ConfirmationAction.keepWriting
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state.alertToast)
    }

    @ViewBuilder
    private var content: some View {
        switch state.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            VStack(spacing: 16) {
                Text("등록 정보를 불러오지 못했어요.")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                RodiRetryButton { send(.retryTapped) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let form):
            formContent(form)
        }
    }

    private func formContent(_ form: CourseRegistrationForm) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        Text(form.sections.basicInfo)
                            .rodiTypography(.heading2)
                            .foregroundStyle(RodiColor.black)
                            .padding(.top, 28)

                        categorySection(form)
                        if !state.draft.selectedCategoryCodes.isEmpty {
                            practiceTypeSection(form)
                        }
                        textInputSection(
                            title: form.sections.caution,
                            text: Binding(
                                get: { state.draft.caution },
                                set: { send(.cautionChanged($0)) }
                            ),
                            spec: form.inputs.caution,
                            isFocused: $isCautionFocused,
                            anchor: .cautionKeyboardAnchor,
                            proxy: proxy
                        )
                        descriptionInputSection(form, proxy: proxy)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if isTextFieldFocused {
                        Color.clear
                            .frame(height: 48)
                            .allowsHitTesting(false)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .contentShape(Rectangle())
                .onTapGesture { dismissKeyboard() }
            }

            if !isTextFieldFocused {
                PrimaryBottomButton(
                    title: "완료",
                    isEnabled: state.isSubmitEnabled,
                    showsDivider: true,
                    action: { send(.submitTapped) }
                )
            }
        }
    }

    private func categorySection(_ form: CourseRegistrationForm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            requiredSectionTitle(form.sections.practiceCategory)

            RodiChipFlow {
                ForEach(form.practiceType.categories) { category in
                    RodiSelectionChip(
                        title: category.label,
                        isSelected: state.draft.selectedCategoryCodes.contains(category.code),
                        action: { send(.categoryTapped(category.code)) }
                    )
                }
            }
        }
    }

    private func practiceTypeSection(_ form: CourseRegistrationForm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            requiredSectionTitle(form.sections.practiceType)

            RodiChipFlow {
                ForEach(selectedPracticeTypes(in: form)) { type in
                    RodiSelectionChip(
                        title: type.label,
                        isSelected: state.draft.selectedPracticeTypeCodes.contains(type.code),
                        action: { send(.practiceTypeTapped(type.code)) }
                    )
                }
            }
        }
    }

    private func textInputSection(
        title: String,
        text: Binding<String>,
        spec: CourseRegistrationTextInputSpec,
        isFocused: FocusState<Bool>.Binding,
        anchor: ScrollTarget,
        proxy: ScrollViewProxy,
        isRequired: Bool = false
    ) -> some View {
        let focused = isFocused.wrappedValue
        return VStack(alignment: .leading, spacing: 12) {
            if isRequired {
                requiredSectionTitle(title)
            } else {
                Text(title)
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
            }

            VStack(alignment: .trailing, spacing: 8) {
                RodiTextField(
                    text: text,
                    placeholder: spec.placeholder,
                    characterLimit: spec.maxLength,
                    isFocused: isFocused
                )
                .padding(.vertical, 14)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                }
            }

        }
        .id(anchor)
        .onChange(of: focused) { isNowFocused in
            guard isNowFocused else { return }
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(anchor, anchor: .bottom)
                }
            }
        }
    }

    private func descriptionInputSection(
        _ form: CourseRegistrationForm,
        proxy: ScrollViewProxy
    ) -> some View {
        let focused = isDescriptionFocused
        return VStack(alignment: .leading, spacing: 12) {
            requiredSectionTitle(form.sections.description)

            CourseRegistrationDescriptionField(
                text: Binding(
                    get: { state.draft.description },
                    set: { send(.descriptionChanged($0)) }
                ),
                spec: form.inputs.description,
                hasStartedInput: state.hasStartedDescriptionInput,
                isFocused: $isDescriptionFocused
            )
        }
        .id(ScrollTarget.descriptionKeyboardAnchor)
        .onChange(of: focused) { isNowFocused in
            guard isNowFocused else { return }
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(ScrollTarget.descriptionKeyboardAnchor, anchor: .bottom)
                }
            }
        }
    }

    private func selectedPracticeTypes(in form: CourseRegistrationForm) -> [CourseRegistrationPracticeType] {
        form.practiceType.categories
            .filter { state.draft.selectedCategoryCodes.contains($0.code) }
            .flatMap(\.practiceTypes)
    }

    private func requiredSectionTitle(_ title: String) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)
            Text("*")
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.primary)
        }
    }

    private var isTextFieldFocused: Bool {
        isCautionFocused || isDescriptionFocused
    }

    private func dismissKeyboard() {
        isCautionFocused = false
        isDescriptionFocused = false
    }

    private enum ConfirmationAction {
        case discard
        case keepWriting
    }
}

private struct CourseRegistrationAlertToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image("ic_alert_circle")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
            Text(message)
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.white)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x434343))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
