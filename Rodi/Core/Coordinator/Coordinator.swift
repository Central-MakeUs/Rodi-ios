import Combine
import SwiftUI

/// 하나의 typed NavigationStack path와 전환 중복 방지 정책을 소유합니다.
@MainActor
final class Coordinator<Destination: Route>: ObservableObject {
    /// 현재 NavigationStack에 쌓인 route 경로입니다.
    @Published private(set) var path: [Destination]

    private var isTransitioning = false
    private var transitionIdentifier = 0
    private let acceptsSystemPath: ([Destination], [Destination]) -> Bool

    /// 지정한 초기 route 경로로 Coordinator를 생성합니다.
    /// `acceptsSystemPath`는 시스템 뒤로가기 등 NavigationStack이 제안한 path를 수용할지 결정합니다.
    init(
        path: [Destination] = [],
        acceptsSystemPath: @escaping ([Destination], [Destination]) -> Bool = { _, _ in true }
    ) {
        self.path = path
        self.acceptsSystemPath = acceptsSystemPath
    }

    /// NavigationStack의 시스템 뒤로가기 결과를 Coordinator에 반영하는 Binding입니다.
    var pathBinding: Binding<[Destination]> {
        Binding(
            get: { self.path },
            set: { [weak self] path in
                self?.synchronizeSystemPath(path)
            }
        )
    }

    /// View와 feature에 전달할 typed navigation 인터페이스입니다.
    var router: Router<Destination> {
        Router(
            submitAction: { [weak self] step in
                self?.submit(step)
            },
            performAction: { [weak self] plan in
                self?.perform(plan)
            }
        )
    }

    /// 일반 전환 단계를 현재 경로에 적용합니다.
    ///
    /// 전환 애니메이션 중 추가 요청은 무시해 연속 탭으로 route가 중복되는 일을 막습니다.
    func submit(_ step: NavigationStep<Destination>) {
        guard !isTransitioning else { return }

        let plan = NavigationPlan(steps: [step])
        transition(to: plan.applying(to: path))
    }

    /// 여러 전환 단계를 적용한 최종 경로로 한 번에 이동합니다.
    ///
    /// `A → B → C` 계획은 중간 화면을 순차 표시하지 않고 C가 포함된 최종 경로만 반영합니다.
    func perform(_ plan: NavigationPlan<Destination>) {
        guard !isTransitioning else { return }
        transition(to: plan.applying(to: path))
    }

    private func transition(to nextPath: [Destination]) {
        guard path != nextPath else { return }

        isTransitioning = true
        transitionIdentifier &+= 1
        let identifier = transitionIdentifier

        if #available(iOS 17.0, *) {
            var transaction = Transaction(animation: .default)
            transaction.addAnimationCompletion(criteria: .logicallyComplete) { [weak self] in
                Task { @MainActor in
                    self?.finishTransition(identifier: identifier)
                }
            }

            withTransaction(transaction) {
                path = nextPath
            }
        } else {
            withAnimation(.default) {
                path = nextPath
            }

            Task { @MainActor [weak self] in
                await Task.yield()
                self?.finishTransition(identifier: identifier)
            }
        }
    }

    private func finishTransition(identifier: Int) {
        guard transitionIdentifier == identifier else { return }
        isTransitioning = false
    }

    private func synchronizeSystemPath(_ nextPath: [Destination]) {
        guard path != nextPath else { return }
        guard acceptsSystemPath(path, nextPath) else { return }

        // 사용자가 뒤로가기 제스처를 완료하면 진행 중인 자동 전환보다 실제 path를 우선합니다.
        transitionIdentifier &+= 1
        isTransitioning = false
        path = nextPath
    }
}
