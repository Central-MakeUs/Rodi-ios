# App 레이어 규칙

## 목적

`App`은 앱 조립, 프로세스·scene 수명, 최상위 화면 진입을 관리한다. 제품 기능의 세부 구현이 아닌 composition root를 둔다.

## MUST

- MUST `RodiApp`, AppDelegate, Root, 최상위 scene lifecycle과 `AppDependencies` 조립을 App에 둔다.
- MUST 앱 시작에 필요한 폰트, 로깅, 외부 SDK 초기화의 순서와 환경 분기를 App에서 명시한다.
- MUST `RootView`가 최상위 route와 feature root의 조립만 담당하게 한다.
- MUST `AppDependencies`에서 Data 구현체를 Domain repository protocol로 조립하고 필요한 feature에 생성자로 전달한다.
- MUST App 전역 singleton이 repository 또는 store 초기화가 필요하면 `AppDependencies`에서 한 번만 configure하고, RootView에서 직접 configure하지 않는다.
- MUST 최상위 인증·온보딩·메인 화면 전환의 소유권을 명확한 App route 또는 root state에 둔다.
- SHOULD 앱 활성화·비활성화 이벤트를 feature가 해석할 typed Action으로 전달한다.
- SHOULD App lifecycle callback은 짧게 유지하고, feature의 async work·cancellation·재시도 정책은 해당 Feature Reducer 또는 Service가 소유하게 한다.

## MUST NOT

- MUST NOT Feature 화면 UI, Feature Reducer의 세부 상태 전이, DTO, Mapper를 App에 둔다.
- MUST NOT `RootView`에서 API 요청, 제품 정책 판단, repository 구현체 생성 외의 I/O를 수행한다.
- MUST NOT Feature마다 별도의 전역 의존성 graph 또는 service locator를 만든다.
- MUST NOT App 수명 이벤트를 이유로 Feature State를 무조건 초기화한다.
- MUST NOT `Task {}` 또는 `Task.detached`를 App lifecycle callback에 추가해 feature I/O를 직접 실행한다.
- MUST NOT `@MainActor`를 App 조립 코드 전체에 관성적으로 붙인다. UIKit·SDK의 실제 main-thread 제약과 Root State 조립 경계만 확인한다.

## 검토 기준

- 앱 진입 파일을 읽고 특정 코스·후기·회원 기능을 이해해야 한다면 해당 책임을 Feature 또는 Domain/Data로 이동한다.
- dependency 조립 변경 뒤에는 Dev Debug build와 로그인·Root 전환·앱 재진입의 최소 흐름을 확인한다.
- lifecycle 변경 뒤에는 background/foreground 반복, 중복 lifecycle event, 진행 중인 request의 늦은 응답을 함께 확인한다.
