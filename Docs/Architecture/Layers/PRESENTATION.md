# Presentation 레이어 규칙

## 목적

`Presentation`은 Feature별 화면 렌더링, 사용자 의도, 상태 전이, Effect orchestration을 관리한다. 서버 표현이 아닌 Domain 계약과 화면 전용 상태를 사용한다.

## MUST

- MUST Feature root에 진입 View와 Reducer를 두고, root는 조립·최종 Delegate 중재에 집중하게 한다.
- MUST View가 State를 렌더링하고 사용자·runtime event를 Action으로 전달하게 한다.
- MUST Reducer가 상태 전이, Effect 시작·취소, 중복 요청 방지, stale response 판단을 소유하게 한다.
- MUST child Reducer가 필요한 결과만 typed Delegate로 부모에 전달하게 한다.
- MUST `Component`, `SubView`, `SubPage`, `Model`, `Service`, `Adapter`와 named child feature를 실제 책임이 생길 때만 사용한다.
- MUST Feature Service와 Adapter가 Store·Reducer State·SwiftUI View를 소유하지 않게 한다.
- MUST Feature의 로컬 초안 payload를 화면 session·route로 복원하거나 완료 시 정리하는 정책은 해당 Feature의 Service에 둔다. `Data/Local`은 저장 구현만 담당한다.
- MUST Reducer Effect 또는 명시적 owner를 통해 비동기 작업의 lifetime, cancellation, stale-result 판단을 소유한다.
- MUST `await` 뒤 route, request revision, cancellation 또는 필요한 State가 여전히 유효한지 확인한 뒤에만 결과를 반영한다.
- MUST selectable row, tile, card, container의 빈 영역을 `Button`과 `contentShape(Rectangle())`로 같은 primary action에 연결한다.
- SHOULD Feature 안에서 두 화면 이상 재사용되는 UI만 `Component`로 분리한다.
- SHOULD UI 전용 선택값, 표시 모델, route payload를 Domain Entity와 구분해 `Model`에 둔다.

## 폴더 기준

- MUST `Component`에는 feature 내 여러 화면에서 재사용되거나 독립 interaction 계약을 가진 UI를 둔다.
- MUST `Model`에는 표시 모델, route, 선택값과 feature enum을 둔다. 별도 `Enum` 폴더는 만들지 않는다.
- MUST `Service`에는 외부 I/O, SDK 호출 또는 State를 모르는 순수 계산을 둔다.
- MUST `Adapter`에는 SwiftUI와 UIKit·외부 SDK의 bridge, delegate, lifecycle 연결을 둔다. `Service`로 흡수하지 않는다.
- MUST `SubPage`에는 navigation destination, full-screen 단계, 독립 modal처럼 독립적으로 렌더링되는 화면을 둔다.
- SHOULD 단일 화면의 시각 분해는 같은 파일의 `private extension`과 `// MARK: -`를 우선한다. 별도 파일이 필요하면 가장 가까운 화면 아래의 `SubView`에 둔다.
- MUST NOT `SubView`, `Section`, `Enum`을 feature 최상위 분류로 사용한다. 독립 State·Action·Reducer를 가진 영역은 실제 기능 이름의 직접 폴더로 둔다.
- MUST `PracticeTracking` root에는 `PracticeTrackingView`와 `PracticeTrackingReducer`만 두고, 앱 복귀 정책은 `Return`, lifecycle bridge는 `Adapter`, 측정·저장 구현은 `Service`에 둔다. Live Activity Widget UI와 app·extension 공유 `ActivityAttributes`는 `RodiPracticeLiveActivity/`에, 앱에서 start/sync/end를 수행하는 app-only runtime service는 `RodiPracticeLiveActivity/AppSupport`에 둔다.
- MUST `Review` root에는 `ReviewView`와 `ReviewReducer`만 두고, 전역 진입·완료 갱신·Snackbar 중재와 조립은 `Flow`, 재진입 권유는 `Prompt`, 후기 작성·수정은 `Writing`, 미방문 사유는 `SkipReason`에 둔다.
- MUST Review와 PracticeTracking이 서로의 State를 읽지 않게 하고, 연습 복귀 후기 권유와 선택 결과는 Root가 typed Delegate로 중계하게 한다.

## MUST NOT

- MUST NOT DTO, `NetworkManager`, API Target, DataSource, RepositoryImpl을 View 또는 Reducer에서 직접 사용한다.
- MUST NOT View `body`에 비동기 제품 로직, API 요청, 복잡한 business decision을 숨긴다.
- MUST NOT View의 `Task {}` 또는 `Task.detached`로 lifecycle-bound 제품 I/O를 시작한다. View는 Action만 보내고 Reducer Effect가 작업을 소유한다.
- MUST NOT `@MainActor`를 compiler error 회피용으로 사용하거나, `Task.detached`로 isolation 오류를 우회한다.
- MUST NOT broad `catch`로 cancellation을 일반 실패처럼 삼킨 뒤 종료된 화면의 State를 갱신한다.
- MUST NOT child가 sibling State를 읽거나 sibling Action을 직접 전송하게 한다.
- MUST NOT 단지 파일 크기만 줄이기 위해 책임 없는 폴더·Service·named child feature를 만든다.
- MUST NOT Figma UI를 이유로 고정 화면 크기, 직접 `UIScreen.main`, 새 `GeometryReader`, 반복 `.offset`을 기본 선택으로 사용한다.

## 리팩터링 트리거

현재 파일별 감사 결과, 우선순위와 진행 상태는 [PRESENTATION_REFACTORING.md](../../Refactoring/PRESENTATION_REFACTORING.md)에서 관리한다. 이 문서는 안정적인 규칙 원본으로 유지하며, 개별 작업 백로그를 직접 쌓지 않는다.

다음은 기능 작업과 분리한 작은 리팩터링 작업을 우선 검토해야 하는 신호다.

- MUST DTO·RemoteDataSource·RepositoryImpl·`NetworkManager` 직접 의존을 Domain contract 주입으로 교체한다.
- MUST 서로 독립적인 화면 단계 세 개 이상의 State·Action·Effect를 한 feature root가 함께 소유하면 child Reducer와 typed Delegate로 분리한다.
- MUST 실제 사용 의존성 일부만 필요한 Reducer에 전체 `AppDependencies`를 주입하지 않는다. 필요한 protocol 또는 feature 범위 Dependencies로 축소한다.
- MUST Debug 전용 화면·테스트 API를 제품 Component·목록 렌더링 책임과 섞지 않는다. Debug 전용 진입점과 구현을 분리한다.
- MUST 같은 feature 화면 생성·완료 callback 조립이 두 곳 이상 복제되면 상위 factory 또는 공통 조립 지점으로 모은다.
- SHOULD 하나의 View 또는 Reducer가 서로 다른 UI 책임 또는 Effect 군을 함께 가진 채 500줄 이상이면 실제 책임 단위의 `SubPage`, `Component`, `Service`, `Adapter` 또는 named child feature 분리를 검토한다.
- SHOULD root View initializer가 많은 callback·state를 받아 호출 누락 위험이 생기면 typed route·delegate payload 또는 상위 flow State로 묶는다.
- SHOULD 목록 UI가 행·empty·error·menu·dialog를 모두 소유하면 재사용 UI와 상태 선택 책임을 분리한다.
- SHOULD SDK gesture·height 관찰이 일반 SwiftUI 화면 조립과 섞이면 Adapter 또는 전용 helper로 경계를 만든다.
- SHOULD 단일 화면 표현만 응집된 300줄 안팎 파일은 같은 파일의 `private extension`과 `// MARK: -`를 우선 사용하며, 줄 수만으로 분리하지 않는다.

## 검토 기준

- Feature 변경 시 loading·empty·error·success, 뒤로가기·dismiss, 중복 탭, 늦은 응답을 함께 검토한다.
- `@MainActor`, `Task`, actor, cancellation을 변경하면 작업 owner, cancellation 경로, `await` 뒤 최신성 판단, main actor에서 수행되는 비용을 함께 검토한다.
- foldering 변경 뒤에는 filesystem-synchronized group, route·Delegate, Dev Debug build를 확인한다.
- Figma UI 작업은 `Docs/Guides/UI_FIGMA.md`와 project SwiftUI skill의 iOS 16.1 제약을 추가로 따른다.
- MUST 구조 리팩터링 커밋과 사용자 기능 변경 커밋을 분리한다.
- MUST 구조 변경 뒤 사용자 동작·문구·Figma 계약·Swagger 계약이 바뀌지 않았는지 확인한다.
