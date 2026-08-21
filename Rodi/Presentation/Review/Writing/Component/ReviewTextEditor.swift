import SwiftUI

struct ReviewTextEditor: UIViewRepresentable {
    @Binding private var text: String
    @Binding private var isFocused: Bool

    private let characterLimit: Int

    init(
        text: Binding<String>,
        characterLimit: Int,
        isFocused: Binding<Bool>
    ) {
        _text = text
        _isFocused = isFocused
        self.characterLimit = characterLimit
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = ReviewInputTextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = .pretendard(size: 14, weight: .medium)
        textView.textColor = UIColor(RodiColor.black)
        textView.tintColor = UIColor(RodiColor.primary)
        textView.textContainerInset = .init(top: 16, left: 16, bottom: 16, right: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.lineBreakMode = .byCharWrapping
        textView.isScrollEnabled = true
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self

        if textView.text != text {
            textView.text = text
        }

        if !isFocused, textView.isFirstResponder {
            textView.resignFirstResponder()
        }
    }
}

private final class ReviewInputTextView: UITextView {
    override var intrinsicContentSize: CGSize {
        .init(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
}

// MARK: - UITextViewDelegate
extension ReviewTextEditor {

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: ReviewTextEditor

        init(parent: ReviewTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {
            let currentText = textView.text as NSString
            let updatedText = currentText.replacingCharacters(in: range, with: text)
            return updatedText.count <= parent.characterLimit
        }
    }
}
