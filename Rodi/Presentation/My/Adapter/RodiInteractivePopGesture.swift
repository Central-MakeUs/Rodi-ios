import SwiftUI

/// 커스텀 navigation header에서도 시스템 interactive-pop을 유지합니다.
struct RodiInteractivePopGestureEnabler: UIViewControllerRepresentable {
    let isEnabled: Bool

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func makeUIViewController(context: Context) -> RodiPopGestureHostingViewController {
        RodiPopGestureHostingViewController(isEnabled: isEnabled)
    }

    func updateUIViewController(
        _ viewController: RodiPopGestureHostingViewController,
        context: Context
    ) {
        viewController.update(isEnabled: isEnabled)
    }

    static func dismantleUIViewController(
        _ viewController: RodiPopGestureHostingViewController,
        coordinator: Void
    ) {
        viewController.restoreInteractivePopGesture()
    }
}

final class RodiPopGestureHostingViewController: UIViewController {
    private var isPopGestureEnabled: Bool
    private weak var configuredNavigationController: UINavigationController?

    init(isEnabled: Bool) {
        isPopGestureEnabled = isEnabled
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        applyInteractivePopGesturePolicy()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyInteractivePopGesturePolicy()
    }

    func update(isEnabled: Bool) {
        isPopGestureEnabled = isEnabled
        applyInteractivePopGesturePolicy()
    }

    func restoreInteractivePopGesture() {
        configuredNavigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    private func applyInteractivePopGesturePolicy() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            guard let navigationController = self.nearestNavigationController(),
                  let gestureRecognizer = navigationController.interactivePopGestureRecognizer
            else { return }

            self.configuredNavigationController = navigationController
            gestureRecognizer.isEnabled = self.isPopGestureEnabled
            // SwiftUI가 navigation bar를 숨긴 화면에서도 native interactive-pop의
            // 진행률 기반 전환을 유지하도록 시스템 기본 delegate 제약을 해제합니다.
            if self.isPopGestureEnabled {
                gestureRecognizer.delegate = nil
            }
        }
    }

    private func nearestNavigationController() -> UINavigationController? {
        var current: UIViewController? = self
        while let viewController = current {
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }
            current = viewController.parent
        }
        return nil
    }
}
