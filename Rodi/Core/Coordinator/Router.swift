/// View와 feature가 NavigationStack 전환을 요청하는 공통 인터페이스입니다.
@MainActor
struct Router<Destination: Route> {
    private let submitAction: @MainActor (NavigationStep<Destination>) -> Void
    private let performAction: @MainActor (NavigationPlan<Destination>) -> Void

    /// Coordinator가 제공하는 전환 실행 동작으로 Router를 생성합니다.
    init(
        submitAction: @escaping @MainActor (NavigationStep<Destination>) -> Void,
        performAction: @escaping @MainActor (NavigationPlan<Destination>) -> Void
    ) {
        self.submitAction = submitAction
        self.performAction = performAction
    }

    /// Coordinator가 없는 Preview 등에서 사용할 안전한 빈 Router입니다.
    static var empty: Self {
        Self(
            submitAction: { _ in },
            performAction: { _ in }
        )
    }

    /// 지정한 route를 NavigationStack 최상단에 추가하도록 요청합니다.
    func push(_ route: Destination) {
        submitAction(.push(route))
    }

    /// 현재 route를 지정한 수만큼 제거하도록 요청합니다.
    func pop(count: Int = 1) {
        submitAction(.pop(count: count))
    }

    /// NavigationStack을 root 화면으로 되돌리도록 요청합니다.
    func popToRoot() {
        submitAction(.popToRoot)
    }

    /// 현재 경로를 지정한 route 배열로 교체하도록 요청합니다.
    func replace(with routes: [Destination]) {
        submitAction(.replace(routes))
    }

    /// 여러 전환 단계를 계산한 최종 경로로 한 번에 이동하도록 요청합니다.
    func perform(_ plan: NavigationPlan<Destination>) {
        performAction(plan)
    }
}
