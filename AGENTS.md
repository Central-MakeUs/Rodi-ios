# RODI Agent Guide

RODI는 초보 운전자와 장롱면허 운전자를 위한 지도 기반 운전 연습 장소·코스 탐색 앱이다.

## 공통 제약

- MUST NOT 안전 보장, 사고 예방, 도로 상태, 주차 가능 여부를 보장하거나 암시한다.
- SHOULD `연습 참고`, `연습 적합성`, `난이도`, `연습 추천`, `외부 길안내 연동` 같은 표현을 우선한다.
- MUST NOT Kakao key, OAuth·access·refresh token, App Store Connect private key, `.p8`, local xcconfig secret, private Firebase 파일을 커밋·응답·로그에 노출한다.
- MUST NOT 정확한 사용자 좌표, 원문 검색어, 식별 가능한 서버 응답을 release log나 분석 event에 남긴다.
- MUST NOT 사용자의 명시적 범위 없이 `Rodi/Data/Local`을 수정한다.
- MUST iOS 16.1을 지원한다. 이후 API는 `#available`과 동등한 fallback을 함께 둔다.
- MUST Live Activity UI 변경 전에 변경 내용과 영향을 설명하고 사용자의 명시적 승인을 받는다.

## 보호 영역

- MUST NOT `Rodi/Core/Architecture/MVICore`, `Rodi/Core/Coordinator`, `Rodi/Core/Network` 아래 파일을 수정·이동·이름 변경·삭제한다.
- MUST 해당 영역 변경이 필요하면 쓰기 전에 대상 파일, 이유, 예상 영향을 제시하고 사용자의 명시적 승인을 받는다.
- MAY 보호 영역을 읽고 build 검증에 포함한다. MUST NOT 승인 절차를 우회하기 위한 복사본이나 대체 구현을 만든다.

## 판단과 범위

작업의 원본은 다음 순서로 판단한다.

1. 사용자의 현재 요청과 명시한 범위
2. 보안·개인정보·제품 안전 제약
3. 작업의 원본: 동작·구조는 live code, API는 해당 환경·버전의 Swagger, UI는 Figma node·screenshot
4. 필요한 활성 문서 한 개
5. 적용 조건에 맞는 project skill
6. 일반 지식

- MUST 자연어 요청에서 목표, 대상, 변경 허용 범위, 완료 조건을 파악한다.
- MUST NOT 분석·확인 요청을 코드 수정·커밋·배포 권한으로 확대 해석한다.
- SHOULD 혼합 작업은 실제 필요한 문서만 추가로 읽고, 작업 분류를 사용자에게 강제하지 않는다.
- MUST 현재 동작의 사실은 live code로 확인한다. Architecture·제품 정책 문서가 정의한 의도와 코드가 다르면 코드에 맞춰 문서를 자동 변경하지 말고, 구현 결함인지 문서 drift인지 판정한다.
- MUST Swagger와 DTO가 다르면 endpoint, 환경, 버전을 확인한 뒤에만 계약을 바꾼다.
- MUST 대상 심볼과 인접 구현을 `rg`로 먼저 확인한다.
- MUST 추가 문서·skill·reference를 읽을 때 현재 해결할 의문을 하나 이상 명시할 수 있어야 한다.
- MUST 변경 위치, 유지할 계약, 검증 방법이 확정되면 무관한 문서·reference 탐색을 멈춘다.
- MUST 같은 작업에서 이미 확인했고 변경되지 않은 Figma node·Swagger schema·문서를 반복 조회하지 않는다.
- SHOULD 긴 작업 문서는 공통 규칙과 대상 섹션부터 읽고, 확인된 의존 관계에 따라 범위를 넓힌다. 필수 Skill 지침은 온전히 읽되 참고자료 전체를 자동으로 열지 않는다.
- MUST 일반 탐색·검색에서 `Docs/Archive`와 `Handoff/archive`를 기본 제외한다. 과거 결정·발표·회고의 근거가 필요한 요청에서만 해당 파일로 범위를 확장하며 현재 구현 계약으로 사용하지 않는다. 문서 링크 검사는 Archive도 포함한다.
- MUST 작업 재개 요청에서만 관련 Handoff를 우선 확인한다. TODO는 대상 ID·Feature를 검색하고 전체 목록은 우선순위 검토·전체 감사 때만 읽는다.

작업의 중심에 맞춰 다음 표에서 필요한 문서를 선택한다. 활성 문서 전체를 기본 컨텍스트로 읽지 않는다.

| 요청의 중심 | 시작 문서·필요 구간 |
| --- | --- |
| Figma·SwiftUI·UIKit·asset·layout | [UI_FIGMA.md](Docs/Guides/UI_FIGMA.md) |
| Swagger·DTO·Repository·endpoint 검증 | [API_SWAGGER.md](Docs/API/API_SWAGGER.md) |
| 레이어·MVI·비동기 소유권·리팩터링·주석 | [ARCHITECTURE.md](Docs/Architecture/ARCHITECTURE.md) |
| Dev/Prod·TestFlight·privacy·analytics·버전 | [RELEASE.md](Docs/Release/RELEASE.md), 버전 작업이면 [VERSION_HISTORY.md](Docs/Release/VERSION_HISTORY.md)의 대상 버전 |
| GPS·주행 시나리오 검증 | [GPS_REPLAY_TESTING.md](Docs/Tests/GPS_REPLAY_TESTING.md), 관련 TODO ID·테스트 코드 |
| 남은 작업·우선순위 | [TODO.md](Docs/TODO.md) |

## 작업과 검증

- MUST 최소 범위의 일관된 변경으로 구현하고, 무관한 사용자 변경을 보존한다.
- MUST 변경 뒤 소유 책임, iOS 16.1, 개인정보, 오래된 문서, diff 범위를 검토한다.
- MUST 코드·구조 변경 뒤 아래 Dev Debug build를 실행한다.

```sh
xcodebuild -project Rodi.xcodeproj -scheme "Rodi Dev" -configuration Debug -destination "generic/platform=iOS Simulator" build
```

- MUST `RodiTests`를 실행했을 때 정확한 명령과 통과·실패를 build와 구분해 보고한다.
- MUST build, 자동 테스트, 정적 검사, 수동 QA, 실기기 검증을 서로 다른 결과로 보고한다.
- MUST 문서·skill만 변경한 작업에는 Xcode build를 실행하지 않아도 된다.
- SHOULD 문서 변경 뒤 `bash Scripts/validate_documentation.sh`로 로컬 링크와 오래된 활성 안내를 확인한다.
- MUST 작업 종료 전 `git diff --check`와 민감정보·local file 유입 여부를 확인한다.

## 문서와 Handoff

- MUST 새 프로젝트 문서를 `Docs/` 아래에 한국어로 작성한다. 개인 작업 연속성 기록만 `Handoff/`에 둔다.
- MUST 규범 문서에서만 `MUST`, `MUST NOT`, `SHOULD`를 사용한다. 배경·예시·과거 기록에는 사용하지 않는다.
- SHOULD 반복되는 판단을 줄이는 규칙만 가장 좁은 권위 문서에 추가한다.
- MUST 실행 규칙을 수정한 뒤 관련 지침을 다시 읽고, 이전 대화에 주입된 규칙과 차이가 있으면 현재 요청·적용 가능한 지침을 대조한다. 파일 수정만으로 실행 환경의 지침까지 갱신됐다고 가정하지 않는다.
- SHOULD 규칙 개편의 실제 효과는 새 작업의 대표 요청으로 확인한다. 현재 작업의 정적 대조를 독립적인 실행 검증으로 보고하지 않는다.
- MUST NOT 한 번의 선호·사례를 새 skill·문서·전역 규칙으로 일반화한다.
- MUST 후속 작업자가 이어받아야 할 상태가 바뀐 경우에만 자신의 `Handoff/{GitOwnerName}_HandOff.md`를 갱신한다.
- MUST 과거 상세 기록은 `Handoff/archive/`로 옮기고, Handoff는 현재 기준 브랜치·커밋·다음 작업·검증 결과만 유지한다.
- MUST `Handoff/INDEX.md`를 작업자와 파일 위치의 색인으로만 유지하고, 진행 상태를 중복 기록하지 않는다.
- MUST NOT Handoff를 TODO, 릴리스 이력의 원본으로 사용하거나 같은 상태를 복제한다.

## Skill 적용

- MUST Figma URL 또는 node-id 구현 요청에서 [UI_FIGMA.md](Docs/Guides/UI_FIGMA.md), `.agents/skills/rodi-swiftui`, 현재 실행 환경이 요구하는 `figma-design-to-code` 지침을 기본 경로로 사용한다. `get_design_context`와 `get_screenshot` 호출 조건은 해당 지침을 따른다.
- MUST 범용 `figma-swiftui`가 현재 실행 환경에서 필수이거나 사용자가 명시한 경우 적용한다. 그 밖에는 RODI 지침만으로 해결되지 않는 SwiftUI 번역 문제가 확인된 경우에 추가하며, RODI의 iOS 16.1·design system·custom navigation 계약을 우선한다.
- MUST SwiftUI 구현·리뷰에 `.agents/skills/rodi-swiftui`를 사용한다. 단순 UI 작업을 이유로 성능 최적화나 공통 Component 개편까지 범위를 넓히지 않는다.
- MUST `.agents/skills/swiftui-expert-skill`을 일반 SwiftUI 작업의 두 번째 기본 skill로 함께 읽지 않는다. 상태 소유·navigation·접근성·API 현대화처럼 프로젝트 skill만으로 해결되지 않는 주제가 실제 범위일 때만 관련 reference를 선택한다.
- SHOULD async 수명, cancellation, reentrancy, MainActor responsiveness의 변경·진단에는 `.agents/skills/swift-concurrency-performance`를 사용한다.
- MUST launch·SwiftUI rendering·runtime·perceived performance·profiling skill을 요청의 실제 증상 또는 측정 과제가 해당 영역일 때만 사용한다. 성능 가능성만으로 여러 skill을 동시에 확장하지 않는다.
- MUST 성능 최적화는 재현·측정·검증 계획이 있을 때만 수행한다. skill을 읽거나 성능 위험을 발견한 사실만으로 최적화 권한이 생기지 않는다.
- MUST NOT project skill의 upstream 내용을 자동 갱신한다. upstream diff, license, iOS 16.1·MVICore·Figma 호환성을 검토한 뒤에만 변경한다.

## 상호작용과 Git

- MUST selectable row, tile, card, container의 전체 visible rectangle을 `Button`과 `contentShape(Rectangle())`로 탭 가능하게 한다. 별도 control이 없는 빈 영역도 같은 기본 동작을 수행한다.
- MUST 분리 staging·push 요청 시 feature 또는 책임 단위로 커밋을 나눈다.
- MUST Conventional Commit type을 실제 변경에 맞춰 `feat`, `fix`, `hotfix`, `refactor`, `chore`, `docs`, `test`, `style` 중에서 선택한다.
- MUST 커밋 제목을 `<type>: <한글 명사형>`으로 쓰고, `구현`, `분리`, `정리` 같은 명사형으로 끝낸다.
- MUST `refactor`를 동작 보존 구조 변경에, `chore`를 도구·저장소 유지보수에, `docs`를 문서 변경에 사용한다.
- MUST NOT 무관한 기능·리팩터링·문서 변경을 하나의 커밋에 섞는다.
- MUST stage별 diff 범위를 확인한 뒤 commit 또는 push한다.
- MUST Dev TestFlight 업로드에 `bundle exec fastlane ios dev_beta`, Prod TestFlight 업로드에 `bundle exec fastlane ios prod_beta`를 사용한다.

## 완료 보고

- MUST 결과, 변경하지 않은 범위, 실행한 검증과 미검증 사항을 구분해 짧게 보고한다.
- MUST 최종 판단에 사용한 규칙 원본과 핵심 근거 Markdown만 `읽은 문서` 줄에 링크로 적는다. 전체 열람 목록은 사용자가 문서 감사를 요청했을 때만 제공한다.
- MUST NOT 정확한 수치가 없는 토큰 사용량을 추정하거나 placeholder로 보고한다.
- MUST NOT 문서 파일 수·줄 수 감소를 토큰 절감률로 환산한다.
