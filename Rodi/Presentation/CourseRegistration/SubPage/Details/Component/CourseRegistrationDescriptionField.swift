import SwiftUI

struct CourseRegistrationDescriptionField: View {
    @Binding private var text: String

    private let spec: CourseRegistrationTextInputSpec
    private let hasStartedInput: Bool
    private let isFocused: FocusState<Bool>.Binding

    init(
        text: Binding<String>,
        spec: CourseRegistrationTextInputSpec,
        hasStartedInput: Bool,
        isFocused: FocusState<Bool>.Binding
    ) {
        _text = text
        self.spec = spec
        self.hasStartedInput = hasStartedInput
        self.isFocused = isFocused
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            RodiTextField(
                text: $text,
                placeholder: "예) 교차로 연습하기 좋은 코스에요",
                characterLimit: spec.maxLength,
                isFocused: isFocused
            )
            .padding(.vertical, 14)
            .background(RodiColor.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            }

            if hasStartedInput {
                HStack(spacing: 8) {
                    if isInvalid {
                        Text("최소 \(minimumLength)자 이상 입력해주세요")
                            .rodiTypography(.caption1Medium)
                            .foregroundStyle(RodiColor.informationCancel)
                    }
                    Spacer(minLength: 0)
                    Text("\(text.count)/\(spec.maxLength)")
                        .rodiTypography(.caption1Medium)
                        .foregroundStyle(RodiColor.gray500)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isInvalid ? "최소 \(minimumLength)자 이상 입력해야 합니다" : "\(text.count)자 입력됨")
    }

    private var minimumLength: Int {
        max(spec.minLength ?? 0, 10)
    }

    private var isInvalid: Bool {
        hasStartedInput
            && text.trimmingCharacters(in: .whitespacesAndNewlines).count < minimumLength
    }

    private var borderColor: Color {
        if isInvalid {
            RodiColor.informationCancel
        } else if isFocused.wrappedValue {
            RodiColor.gray850
        } else {
            RodiColor.gray300
        }
    }
}
