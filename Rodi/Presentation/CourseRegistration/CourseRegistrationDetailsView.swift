import SwiftUI

struct CourseRegistrationDetailsView: View {
    private enum ScrollTarget: Hashable {
        case cautionKeyboardAnchor
        case descriptionKeyboardAnchor
    }

    @Environment(\.screenSafeAreaInsets) private var screenSafeAreaInsets
    @FocusState private var isCautionFocused: Bool
    @FocusState private var isDescriptionFocused: Bool

    let loadState: CourseRegistrationDetailsLoadState
    let draft: CourseRegistrationDetailsDraft
    let isSubmitting: Bool
    let alertToast: CourseRegistrationAlertToastState?
    let isDiscardConfirmationPresented: Bool
    let categoryAction: (String) -> Void
    let practiceTypeAction: (String) -> Void
    let cautionChangedAction: (String) -> Void
    let descriptionChangedAction: (String) -> Void
    let retryAction: () -> Void
    let backAction: () -> Void
    let discardAction: () -> Void
    let keepWritingAction: () -> Void
    let submitAction: () -> Void
    let alertDismissAction: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CourseRegistrationHeader(title: "코스 등록", closeAction: backAction)
                .background(RodiColor.white)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, screenSafeAreaInsets.top)
        .padding(.bottom, isTextFieldFocused ? 0 : screenSafeAreaInsets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(RodiColor.white)
        .ignoresSafeArea(.container)
        .ignoresSafeArea([], edges: .bottom)
        .overlay(alignment: .bottom) {
            if let alertToast {
                CourseRegistrationAlertToast(message: alertToast.message)
                    .padding(.horizontal, 16)
                    .padding(.bottom, isTextFieldFocused ? 24 : 96)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .task(id: alertToast.revision) {
                        try? await Task.sleep(for: .seconds(3))
                        guard !Task.isCancelled else { return }
                        alertDismissAction(alertToast.revision)
                    }
            }
        }
        .overlay {
            if isDiscardConfirmationPresented {
                ReviewDiscardConfirmationView(
                    send: { action in
                        switch action {
                        case .discard: discardAction()
                        case .keepWriting: keepWritingAction()
                        }
                    },
                    confirmAction: ConfirmationAction.discard,
                    cancelAction: ConfirmationAction.keepWriting
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: alertToast)
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed:
            VStack(spacing: 16) {
                Text("등록 정보를 불러오지 못했어요.")
                    .rodiTypography(.body1SemiBold)
                    .foregroundStyle(RodiColor.black)
                Button(action: retryAction) {
                    Text("다시 시도")
                        .rodiTypography(.buttonMedium)
                        .foregroundStyle(RodiColor.primary)
                }
                .buttonStyle(.plain)
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
                        practiceTypeSection(form)
                        textInputSection(
                            title: form.sections.caution,
                            text: Binding(get: { draft.caution }, set: cautionChangedAction),
                            spec: form.inputs.caution,
                            isFocused: $isCautionFocused,
                            anchor: .cautionKeyboardAnchor,
                            proxy: proxy
                        )
                        textInputSection(
                            title: form.sections.description,
                            text: Binding(get: { draft.description }, set: descriptionChangedAction),
                            spec: form.inputs.description,
                            isFocused: $isDescriptionFocused,
                            anchor: .descriptionKeyboardAnchor,
                            proxy: proxy,
                            showsCounter: true
                        )
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
                    isEnabled: canSubmit(form) && !isSubmitting,
                    showsDivider: true,
                    action: submitAction
                )
            }
        }
    }

    private func categorySection(_ form: CourseRegistrationForm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(form.sections.practiceCategory)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            RodiChipFlow {
                ForEach(form.practiceType.categories) { category in
                    RodiSelectionChip(
                        title: category.label,
                        isSelected: draft.selectedCategoryCodes.contains(category.code),
                        action: { categoryAction(category.code) }
                    )
                }
            }
        }
    }

    private func practiceTypeSection(_ form: CourseRegistrationForm) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(form.sections.practiceType)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            RodiChipFlow {
                ForEach(selectedPracticeTypes(in: form)) { type in
                    RodiSelectionChip(
                        title: type.label,
                        isSelected: draft.selectedPracticeTypeCodes.contains(type.code),
                        action: { practiceTypeAction(type.code) }
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
        showsCounter: Bool = false
    ) -> some View {
        let focused = isFocused.wrappedValue
        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .rodiTypography(.body1SemiBold)
                .foregroundStyle(RodiColor.black)

            VStack(alignment: .trailing, spacing: 8) {
                RodiTextField(
                    text: text,
                    placeholder: showsCounter ? "최소 10자 이상 입력해주세요." : spec.placeholder,
                    characterLimit: showsCounter ? 30 : 100,
                    isFocused: isFocused
                )
                .padding(.vertical, 14)
                .background(RodiColor.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(focused ? RodiColor.gray850 : RodiColor.gray300, lineWidth: 1)
                }

                if showsCounter {
                    Text("\(text.wrappedValue.count)/\(spec.maxLength)")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray500)
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

    private func selectedPracticeTypes(in form: CourseRegistrationForm) -> [CourseRegistrationPracticeType] {
        guard let defaultCategory = form.practiceType.categories.first else { return [] }
        let additionallySelectedCategories = form.practiceType.categories.filter {
            $0.code != defaultCategory.code && draft.selectedCategoryCodes.contains($0.code)
        }
        return ([defaultCategory] + additionallySelectedCategories)
            .flatMap(\.practiceTypes)
    }

    private func canSubmit(_ form: CourseRegistrationForm) -> Bool {
        guard !draft.selectedCategoryCodes.isEmpty, !draft.selectedPracticeTypeCodes.isEmpty else { return false }
        return inputIsPresent(form.inputs.caution, draft.caution)
            && inputIsPresent(form.inputs.description, draft.description)
            && draft.description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }

    private func inputIsPresent(_ spec: CourseRegistrationTextInputSpec, _ text: String) -> Bool {
        !spec.required || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
