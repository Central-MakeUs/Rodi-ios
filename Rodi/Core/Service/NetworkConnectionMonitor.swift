//
//  NetworkConnectionMonitor.swift
//  Rodi
//

import Combine
import Foundation
import Network

@MainActor
final class NetworkConnectionMonitor: ObservableObject {

    enum Status: Equatable {
        case checking
        case connected
        case disconnected
    }

    @Published private(set) var status: Status = .checking

    private let queue = DispatchQueue(label: "store.rodi.network-connection-monitor")
    private var pathMonitor: NWPathMonitor?

    var isDisconnected: Bool {
        status == .disconnected
    }

    init() {
        startMonitoring()
    }

    deinit {
        pathMonitor?.cancel()
    }

    func refresh() {
        startMonitoring()
    }

    private func startMonitoring() {
        pathMonitor?.cancel()
        status = .checking

        let pathMonitor = NWPathMonitor()
        self.pathMonitor = pathMonitor

        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.status = path.status == .satisfied ? .connected : .disconnected
            }
        }
        pathMonitor.start(queue: queue)
    }
}
