//
//  HomeNetworkMonitor.swift
//  Rodi
//

import Network

@MainActor
final class HomeNetworkMonitor {
    private(set) var isNetworkUnavailable = false {
        didSet { onStatusChange?(isNetworkUnavailable) }
    }

    private var monitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "rodi.home.network.monitor")
    private var isStarted = false
    private var onStatusChange: ((Bool) -> Void)?

    func start(onStatusChange: @escaping (Bool) -> Void) {
        self.onStatusChange = onStatusChange
        guard !isStarted else { return }
        isStarted = true

        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let isNetworkUnavailable = path.status != .satisfied
            Task { @MainActor [weak self] in
                self?.isNetworkUnavailable = isNetworkUnavailable
            }
        }
        self.monitor = monitor
        monitor.start(queue: queue)
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        monitor?.pathUpdateHandler = nil
        monitor?.cancel()
        monitor = nil
        onStatusChange = nil
    }
}
