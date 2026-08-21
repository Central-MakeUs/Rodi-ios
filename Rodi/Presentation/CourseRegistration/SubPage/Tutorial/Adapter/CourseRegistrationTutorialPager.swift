import SwiftUI

/// UIPageViewController의 확정 페이지를 reducer에 전달하는 iOS 16.1 호환 Adapter다.
struct CourseRegistrationTutorialPager: UIViewControllerRepresentable {
    let page: Int
    let pages: [AnyView]
    let pageChanged: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        context.coordinator.configure(controller: controller, pages: pages)
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.update(pages: pages)
        context.coordinator.select(page: page, in: controller)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: CourseRegistrationTutorialPager
        private var pages: [UIHostingController<AnyView>] = []
        private weak var pageController: UIPageViewController?
        private var displayedPage = 0
        private var transitionStartPage: Int?
        private var isProgrammaticSelection = false

        init(parent: CourseRegistrationTutorialPager) {
            self.parent = parent
        }

        func configure(controller: UIPageViewController, pages: [AnyView]) {
            pageController = controller
            update(pages: pages)
            controller.dataSource = self
            controller.delegate = self
            displayedPage = min(max(parent.page, 0), self.pages.count - 1)
            controller.setViewControllers([self.pages[displayedPage]], direction: .forward, animated: false)
        }

        func update(pages: [AnyView]) {
            if self.pages.count != pages.count {
                self.pages = pages.map { UIHostingController(rootView: $0) }
            } else {
                for index in self.pages.indices where pages.indices.contains(index) {
                    self.pages[index].rootView = pages[index]
                }
            }
        }

        func select(page: Int, in controller: UIPageViewController) {
            let clamped = min(max(page, 0), pages.count - 1)
            guard !isProgrammaticSelection,
                  transitionStartPage == nil,
                  clamped != displayedPage
            else { return }
            let direction: UIPageViewController.NavigationDirection = clamped > displayedPage ? .forward : .reverse
            isProgrammaticSelection = true
            displayedPage = clamped
            controller.setViewControllers([pages[clamped]], direction: direction, animated: false) { [weak self] _ in
                guard let self else { return }
                self.isProgrammaticSelection = false
            }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            willTransitionTo pendingViewControllers: [UIViewController]
        ) {
            guard !isProgrammaticSelection,
                  let current = pageViewController.viewControllers?.first,
                  let currentIndex = pages.firstIndex(where: { $0 === current }),
                  pendingViewControllers.first.flatMap({ pending in pages.firstIndex(where: { $0 === pending }) }) != nil
            else { return }

            displayedPage = currentIndex
            transitionStartPage = currentIndex
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = pages.firstIndex(where: { $0 === viewController }), index > 0 else { return nil }
            return pages[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = pages.firstIndex(where: { $0 === viewController }), index < pages.count - 1 else { return nil }
            return pages[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            defer { transitionStartPage = nil }
            guard let current = pageViewController.viewControllers?.first,
                  let index = pages.firstIndex(where: { $0 === current })
            else { return }

            displayedPage = index
            guard completed, parent.page != index else { return }
            parent.pageChanged(index)
        }
    }
}

struct CourseRegistrationTutorialProgressView: View {
    let page: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< 3, id: \.self) { index in
                Capsule()
                    .fill(index <= page ? RodiColor.primary : RodiColor.gray200)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 32)
        .accessibilityLabel("튜토리얼 진행 상황")
        .accessibilityValue("3단계 중 \(page + 1)단계")
    }
}
