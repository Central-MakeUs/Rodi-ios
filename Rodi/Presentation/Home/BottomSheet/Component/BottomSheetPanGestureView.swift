import SwiftUI

// TODO: 코드 수정하기 (윤수)
struct BottomSheetPanGestureView: UIViewRepresentable {
    let isEnabled: Bool
    let onChanged: (CGFloat) -> Void
    let onEnded: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isEnabled: isEnabled,
            onChanged: onChanged,
            onEnded: onEnded
        )
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let recognizer = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan)
        )
        recognizer.maximumNumberOfTouches = 1
        recognizer.delegate = context.coordinator
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        uiView.isUserInteractionEnabled = isEnabled
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isEnabled: Bool
        var onChanged: (CGFloat) -> Void
        var onEnded: (CGFloat) -> Void

        init(
            isEnabled: Bool,
            onChanged: @escaping (CGFloat) -> Void,
            onEnded: @escaping (CGFloat) -> Void
        ) {
            self.isEnabled = isEnabled
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isEnabled,
                  let gestureView = recognizer.view else { return }

            let referenceView = gestureView.window ?? gestureView.superview ?? gestureView
            let translationY = recognizer.translation(in: referenceView).y

            switch recognizer.state {
            case .began, .changed:
                onChanged(translationY)

            case .ended, .cancelled, .failed:
                onEnded(translationY)

            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isEnabled,
                  let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
                  let gestureView = panRecognizer.view else { return false }

            let referenceView = gestureView.window ?? gestureView.superview ?? gestureView
            let velocity = panRecognizer.velocity(in: referenceView)
            return abs(velocity.y) > abs(velocity.x)
        }
    }
}
