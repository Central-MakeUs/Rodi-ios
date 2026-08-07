import Foundation

/// NavigationStack에 기록할 화면 전환 단위의 공통 계약입니다.
protocol Route: Hashable {
    /// 앱 전체에서 중복되지 않는 route 식별자입니다.
    var id: String { get }
}
