//
//  RodiLimitedTextField.swift
//  Rodi
//

import SwiftUI

struct RodiTextField: View {
    @Binding private var text: String
    private var isFocused: FocusState<Bool>.Binding

    private let placeholder: String
    private let characterLimit: Int

    init(
        text: Binding<String>,
        placeholder: String,
        characterLimit: Int,
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
            text: limitedTextBinding,
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
        .padding(.horizontal, 16)
        .frame(height: 20)
    }

    private var limitedTextBinding: Binding<String> {
        Binding(
            get: { text },
            set: { updatedText in
                guard updatedText.count <= characterLimit else { return }
                text = updatedText
            }
        )
    }
}
