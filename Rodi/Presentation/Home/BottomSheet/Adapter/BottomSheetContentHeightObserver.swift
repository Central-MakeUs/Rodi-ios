import SwiftUI

struct BottomSheetContentHeightObserver: UIViewRepresentable {
    let onHeightChanged: (CGFloat) -> Void

    func makeUIView(context: Context) -> HeightObservingView {
        HeightObservingView(onHeightChanged: onHeightChanged)
    }

    func updateUIView(_ uiView: HeightObservingView, context: Context) {
        uiView.onHeightChanged = onHeightChanged
    }

    final class HeightObservingView: UIView {
        var onHeightChanged: (CGFloat) -> Void
        private var lastReportedHeight: CGFloat = 0

        init(onHeightChanged: @escaping (CGFloat) -> Void) {
            self.onHeightChanged = onHeightChanged
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let height = bounds.height
            guard height > 0,
                  abs(lastReportedHeight - height) > 0.5
            else {
                return
            }

            lastReportedHeight = height
            DispatchQueue.main.async { [weak self] in
                self?.onHeightChanged(height)
            }
        }
    }
}
