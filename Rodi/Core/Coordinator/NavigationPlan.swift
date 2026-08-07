/// NavigationStack 경로를 변환하는 원자 단위입니다.
enum NavigationStep<Destination: Route> {
    /// 지정한 route를 최상단에 추가합니다.
    case push(Destination)
    /// 최상단부터 지정한 수만큼 route를 제거합니다.
    case pop(count: Int)
    /// 모든 route를 제거해 root 화면으로 돌아갑니다.
    case popToRoot
    /// 현재 경로 전체를 지정한 route 배열로 교체합니다.
    case replace([Destination])
}

/// 여러 화면 전환 단계를 최종 NavigationStack 경로로 계산하는 선언형 계획입니다.
struct NavigationPlan<Destination: Route> {
    /// 현재 path에 적용할 순서 있는 전환 단계입니다.
    let steps: [NavigationStep<Destination>]

    /// 지정한 전환 단계로 계획을 생성합니다.
    init(steps: [NavigationStep<Destination>]) {
        self.steps = steps
    }

    /// 현재 경로에 모든 단계를 적용한 최종 경로를 반환합니다.
    ///
    /// 이 메서드는 화면 전환을 실행하지 않습니다. Coordinator가 반환된 최종 경로를
    /// 한 번만 NavigationStack에 반영하므로 중간 화면이 보이지 않습니다.
    func applying(to initialPath: [Destination]) -> [Destination] {
        steps.reduce(initialPath) { path, step in
            switch step {
            case let .push(route):
                guard path.last != route else { return path }
                return path + [route]

            case let .pop(count):
                let removableCount = min(max(count, 0), path.count)
                guard removableCount > 0 else { return path }
                return Array(path.dropLast(removableCount))

            case .popToRoot:
                return []

            case let .replace(routes):
                return routes
            }
        }
    }
}
