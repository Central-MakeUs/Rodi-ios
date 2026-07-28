//
//  MyInteractivePopGestureEnabler.swift
//  Rodi
//

import SwiftUI
import UIKit

/// 커스텀 헤더를 사용하는 마이페이지에서도 시스템 edge-swipe pop을 유지합니다.
struct MyInteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PopGestureHostingViewController {
        PopGestureHostingViewController()
    }

    func updateUIViewController(_ uiViewController: PopGestureHostingViewController, context: Context) {
        uiViewController.enableInteractivePopGestureIfPossible()
    }
}

final class PopGestureHostingViewController: UIViewController {
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        enableInteractivePopGestureIfPossible()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopGestureIfPossible()
    }

    func enableInteractivePopGestureIfPossible() {
        DispatchQueue.main.async { [weak self] in
            guard let navigationController = self?.navigationController,
                  navigationController.viewControllers.count > 1,
                  let gestureRecognizer = navigationController.interactivePopGestureRecognizer
            else {
                return
            }

            gestureRecognizer.isEnabled = true
            gestureRecognizer.delegate = nil
        }
    }
}
