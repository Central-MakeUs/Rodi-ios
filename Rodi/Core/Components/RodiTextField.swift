//
//  RodiLimitedTextField.swift
//  Rodi
//

import SwiftUI

struct RodiTextField: View {
    @Binding private var text: String
    @State private var editingText = ""
    private var isFocused: FocusState<Bool>.Binding

    private let placeholder: String
    private let characterLimit: Int?

    init(
        text: Binding<String>,
        placeholder: String,
        characterLimit: Int? = nil,
        isFocused: FocusState<Bool>.Binding
    ) {
        _text = text
        self.isFocused = isFocused
        self.placeholder = placeholder
        self.characterLimit = characterLimit
    }

    var body: some View {
        TextField(
            "",
            text: $editingText,
            prompt: Text(placeholder)
                .foregroundColor(RodiColor.gray500)
        )
        .font(RodiTypography.body3Medium.font)
        .tracking(RodiTypography.body3Medium.tracking)
        .foregroundStyle(RodiColor.black)
        .tint(RodiColor.black)
        .focused(isFocused)
        .submitLabel(.done)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .onSubmit { isFocused.wrappedValue = false }
        .onAppear {
            editingText = limited(text)
        }
        .onChange(of: editingText) { updatedText in
            let limitedText = limited(updatedText)
            if editingText != limitedText {
                editingText = limitedText
            }
            if text != limitedText {
                text = limitedText
            }
        }
        .onChange(of: text) { updatedText in
            let limitedText = limited(updatedText)
            if editingText != limitedText {
                editingText = limitedText
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 20)
    }

    private func limited(_ value: String) -> String {
        guard let characterLimit else { return value }
        return String(value.prefix(characterLimit))
    }
}
