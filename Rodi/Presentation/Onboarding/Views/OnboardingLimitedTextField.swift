//
//  OnboardingLimitedTextField.swift
//  Rodi
//

import SwiftUI
import Then

struct OnboardingLimitedTextField: UIViewRepresentable {
    @Binding var text: String

    let placeholder: String
    let characterLimit: Int
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, characterLimit: characterLimit, isFocused: $isFocused)
    }

    func makeUIView(context: Context) -> UITextField {
        UITextField().then {
            $0.delegate = context.coordinator
            $0.backgroundColor = .clear
            $0.font = .pretendard(size: 14, weight: .medium)
            $0.textColor = UIColor(RodiColor.black)
            $0.tintColor = UIColor(RodiColor.black)
            $0.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: UIColor(RodiColor.gray500),
                    .font: UIFont.pretendard(size: 14, weight: .medium)
                ]
            )
            $0.returnKeyType = .done
            $0.borderStyle = .none
            $0.autocorrectionType = .no
            $0.autocapitalizationType = .none
            $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
            $0.leftViewMode = .always
            $0.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
            $0.rightViewMode = .always
            $0.addTarget(
                context.coordinator,
                action: #selector(Coordinator.textFieldDidChange(_:)),
                for: .editingChanged
            )
        }
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text, textField.markedTextRange == nil {
            textField.text = text
        }

        if isFocused, !textField.isFirstResponder {
            textField.becomeFirstResponder()
        } else if !isFocused, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        private let characterLimit: Int
        @Binding private var isFocused: Bool

        init(text: Binding<String>, characterLimit: Int, isFocused: Binding<Bool>) {
            _text = text
            self.characterLimit = characterLimit
            _isFocused = isFocused
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            let currentText = textField.text ?? ""
            guard let swiftRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: swiftRange, with: string)
            return updatedText.count <= characterLimit || textField.markedTextRange != nil
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            guard textField.markedTextRange == nil else { return }

            let limitedText = String((textField.text ?? "").prefix(characterLimit))
            if textField.text != limitedText {
                textField.text = limitedText
            }
            text = limitedText
        }
    }
}
