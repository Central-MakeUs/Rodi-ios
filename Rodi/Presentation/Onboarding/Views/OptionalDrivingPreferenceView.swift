//
//  OptionalDrivingPreferenceView.swift
//  Rodi
//

import SwiftUI
import SnapKit
import Then

struct OptionalDrivingPreferenceView: View {
    let selectedPracticeSituations: [PracticeSituation]
    let selectedVehicleType: VehicleType?
    let drivingGoal: String
    let canProceed: Bool
    let onTogglePracticeSituation: (PracticeSituation) -> Void
    let onSelectVehicleType: (VehicleType) -> Void
    let onUpdateGoal: (String) -> Void
    let onSkip: () -> Void
    let onNext: () -> Void

    @FocusState private var isGoalFieldFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    title

                    VStack(alignment: .leading, spacing: 32) {
                        OnboardingSection(title: "더 연습해보고 싶은 상황이 있나요?", trailing: "최대 3개") {
                            practiceSituationChips
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissGoalKeyboard()
                        }

                        OnboardingSection(title: "주로 타는 차종은 무엇인가요?") {
                            vehicleTypeChips
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissGoalKeyboard()
                        }

                        OnboardingSection(title: "이루고 싶은 운전 목표를 입력해주세요.") {
                            goalTextEditor
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 46 + 10 + 24)
            }
            .scrollDismissesKeyboard(.interactively)

            DualBottomButton(
                secondaryTitle: "건너뛰기",
                primaryTitle: "다음",
                isPrimaryEnabled: canProceed,
                secondaryAction: onSkip,
                primaryAction: onNext
            )
            .opacity(isGoalFieldFocused ? 0 : 1)
            .allowsHitTesting(!isGoalFieldFocused)
            .accessibilityHidden(isGoalFieldFocused)
        }
        .transaction { transaction in
            transaction.animation = nil
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("추가 정보를 입력하면 더 정확해요.")
                .rodiTypography(.heading2)
                .foregroundStyle(RodiColor.black)

            Text("딱 맞는 코스 추천을 위한 선택항목이에요.")
                .rodiTypography(.body3Medium)
                .foregroundStyle(RodiColor.gray600)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            dismissGoalKeyboard()
        }
    }

    private var practiceSituationChips: some View {
        OnboardingChipFlow {
            ForEach(PracticeSituation.allCases) { situation in
                let selectionOrder = selectedPracticeSituations.firstIndex(of: situation).map { $0 + 1 }

                OnboardingChip(
                    title: situation.rawValue,
                    isSelected: selectionOrder != nil,
                    selectionOrder: selectionOrder,
                    action: {
                        dismissGoalKeyboard()
                        onTogglePracticeSituation(situation)
                    }
                )
            }
        }
    }

    private var vehicleTypeChips: some View {
        OnboardingChipFlow {
            ForEach(VehicleType.allCases) { vehicleType in
                OnboardingChip(
                    title: vehicleType.rawValue,
                    isSelected: selectedVehicleType == vehicleType,
                    action: {
                        dismissGoalKeyboard()
                        onSelectVehicleType(vehicleType)
                    }
                )
            }
        }
    }

    private var goalTextEditor: some View {
        OnboardingGoalTextView(
            text: Binding(
                get: { drivingGoal },
                set: onUpdateGoal
            ),
            placeholder: "복잡한 강남 자신있게 운전하기!",
            isFocused: $isGoalFieldFocused
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(height: 100, alignment: .topLeading)
        .background(RodiColor.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(RodiColor.gray300, lineWidth: 1)
        }
    }

    private func dismissGoalKeyboard() {
        isGoalFieldFocused = false
    }
}

private struct OnboardingGoalTextView: UIViewRepresentable {
    @Binding var text: String

    let placeholder: String
    let isFocused: FocusState<Bool>.Binding

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: isFocused)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView().then {
            $0.delegate = context.coordinator
            $0.backgroundColor = .clear
            $0.font = .pretendard(size: 14, weight: .medium)
            $0.textColor = UIColor(RodiColor.black)
            $0.tintColor = UIColor(RodiColor.primary)
            $0.returnKeyType = .done
            $0.isScrollEnabled = false
            $0.textContainerInset = .zero
            $0.textContainer.lineFragmentPadding = 0
        }

        let placeholderLabel = UILabel().then {
            $0.text = placeholder
            $0.font = .pretendard(size: 14, weight: .medium)
            $0.textColor = UIColor(RodiColor.gray500)
            $0.numberOfLines = 1
        }
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        context.coordinator.placeholderLabel = placeholderLabel
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }

        context.coordinator.placeholderLabel?.isHidden = !text.isEmpty

        if isFocused.wrappedValue, !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isFocused.wrappedValue, textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding private var text: String
        private let isFocused: FocusState<Bool>.Binding
        weak var placeholderLabel: UILabel?

        init(text: Binding<String>, isFocused: FocusState<Bool>.Binding) {
            _text = text
            self.isFocused = isFocused
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isFocused.wrappedValue = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isFocused.wrappedValue = false
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            placeholderLabel?.isHidden = !textView.text.isEmpty
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            if replacement == "\n" {
                textView.resignFirstResponder()
                return false
            }

            return true
        }
    }
}
