//
//  NetworkUnavailableOverlayPresenter.swift
//  Rodi
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class NetworkUnavailableOverlayPresenter: ObservableObject {

    private let monitor: NetworkConnectionMonitor
    private var statusCancellable: AnyCancellable?
    private weak var windowScene: UIWindowScene?
    private var overlayWindow: UIWindow?

    init(monitor: NetworkConnectionMonitor) {
        self.monitor = monitor

        statusCancellable = monitor.$status.sink { [weak self] status in
            Task { @MainActor [weak self] in
                self?.updateVisibility(for: status)
            }
        }
    }

    deinit {
        overlayWindow?.isHidden = true
    }

    func attach(to windowScene: UIWindowScene) {
        guard self.windowScene !== windowScene else {
            updateVisibility(for: monitor.status)
            return
        }

        detach()
        self.windowScene = windowScene
        updateVisibility(for: monitor.status)
    }

    func detach() {
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        windowScene = nil
    }

    private func updateVisibility(for status: NetworkConnectionMonitor.Status) {
        guard let windowScene else { return }

        guard status == .disconnected else {
            overlayWindow?.isHidden = true
            return
        }

        let window = overlayWindow ?? makeOverlayWindow(in: windowScene)
        window.isHidden = false
    }

    private func makeOverlayWindow(in windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        window.rootViewController = UIHostingController(
            rootView: NetworkUnavailableView(refreshAction: { [weak monitor] in
                monitor?.refresh()
            })
        )
        overlayWindow = window
        return window
    }
}

struct NetworkUnavailableOverlayHost: UIViewControllerRepresentable {
    let presenter: NetworkUnavailableOverlayPresenter

    func makeUIViewController(context: Context) -> NetworkUnavailableOverlayHostViewController {
        NetworkUnavailableOverlayHostViewController(presenter: presenter)
    }

    func updateUIViewController(_ uiViewController: NetworkUnavailableOverlayHostViewController, context: Context) {
        uiViewController.presenter = presenter
        uiViewController.attachIfPossible()
    }

    static func dismantleUIViewController(_ uiViewController: NetworkUnavailableOverlayHostViewController, coordinator: ()) {
        uiViewController.presenter?.detach()
    }
}

final class NetworkUnavailableOverlayHostViewController: UIViewController {
    weak var presenter: NetworkUnavailableOverlayPresenter?

    init(presenter: NetworkUnavailableOverlayPresenter) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        attachIfPossible()
    }

    func attachIfPossible() {
        guard let windowScene = view.window?.windowScene else { return }
        presenter?.attach(to: windowScene)
    }
}
