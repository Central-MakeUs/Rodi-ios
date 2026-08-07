import Combine

struct ToastStruct: Equatable {
    let message: String
    let state: ToastState
}

enum ToastState: Equatable {
    case none
    case error
    case success
}

@MainActor
final class SnackbarService: ObservableObject {
    @Published private(set) var message: String?
    private var dismissalTask: Task<Void, Never>?

    func show(_ message: String) {
        dismissalTask?.cancel()
        self.message = message
        dismissalTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            self?.message = nil
        }
    }

    func show(_ state: ToastStruct) {
        show(state.message)
    }

    func dismiss() {
        dismissalTask?.cancel()
        message = nil
    }
}
