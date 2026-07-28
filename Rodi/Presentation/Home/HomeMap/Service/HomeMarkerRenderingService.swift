//
//  HomeMarkerRenderingService.swift
//  Rodi
//

import Foundation

@MainActor
final class HomeMarkerRenderingService {
    private var renderingTask: Task<Void, Never>?

    deinit {
        renderingTask?.cancel()
    }

    var isRendering: Bool {
        renderingTask != nil
    }

    func renderProgressively(
        markers: [RodiMapMarker],
        onUpdate: @escaping @MainActor ([RodiMapMarker]) -> Void,
        onFinish: @escaping @MainActor () -> Void
    ) {
        guard !markers.isEmpty else { return }
        guard renderingTask == nil else { return }

        renderingTask = Task { @MainActor [weak self] in
            let initialBatchSize = 80
            let batchSize = 150
            var renderedCount = min(initialBatchSize, markers.count)

            guard !Task.isCancelled else { return }
            onUpdate(Array(markers.prefix(renderedCount)))

            while renderedCount < markers.count {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled else { return }
                renderedCount = min(renderedCount + batchSize, markers.count)
                onUpdate(Array(markers.prefix(renderedCount)))
            }

            onFinish()
            self?.renderingTask = nil
        }
    }

    func cancel() {
        renderingTask?.cancel()
        renderingTask = nil
    }
}
