# RODI 작업 가이드

> 목적: 새 작업에서 어떤 문서를 읽고, 어떤 skill을 적용하며, 어떤 검증을 해야 하는지 빠르게 판단한다.
> 이 문서는 작업 절차 안내다. 기능·API·UI의 실제 계약은 각 주제 문서와 live code를 우선한다.

## 판단 우선순위

작업 판단은 항상 다음 순서로 한다.

1. 사용자의 현재 요청과 명시한 범위
2. `AGENTS.md`의 보안·개인정보·안전·iOS 최소 버전 제약
3. 작업의 원본
   - 동작·구조: live code
   - API: 해당 환경의 Swagger
   - UI: Figma node, screenshot, 인접 구현
4. 아래 주제별 문서 한 개
5. 적용 조건에 맞는 project skill

문서와 live code가 다르면 live code를 우선하고, 문서가 현행 구조를 설명하지 못하면 같은 작업에서 문서를 고친다. Swagger와 DTO가 다르면 endpoint·환경·버전을 먼저 확인하며 추정으로 계약을 바꾸지 않는다.

## 문서 지도

| 문서 | 성격·다루는 내용 | 읽는 시점 | 갱신 시점 |
| --- | --- | --- | --- |
| [ARCHITECTURE.md](../Architecture/ARCHITECTURE.md) | 레이어, MVI, DI, child reducer, feature 폴더 책임 | 폴더 이동, reducer 합성, 책임 분리, 리팩토링 | 구조·책임 경계 변경 시 |
| [Layers/](../Architecture/Layers) | App·Core·Data·Domain·Presentation·Resources별 상세 MUST/MUST NOT | 특정 Layer 리팩터링·감사 | 해당 Layer의 지속 규칙 변경 시 |
| [UI_FIGMA.md](UI_FIGMA.md) | Figma→SwiftUI, token·asset, 레이아웃·접근성·iOS 16.1 UI 기준 | SwiftUI, UIKit bridge, Figma, asset, 화면 리뷰 | 공통 UI 구현 규칙이 변할 때 |
| [CODE_DOCUMENTATION_GUIDE.md](CODE_DOCUMENTATION_GUIDE.md) | 리팩터링 시 한국어 코드 주석·문서화 기준 | 구조 분리·public 경계·예외 처리의 의도 기록이 필요한 경우 | 공통 문서화 원칙이 변할 때 |
| [API_SWAGGER.md](../API/API_SWAGGER.md) | Swagger 확인 순서와 API→DTO→Repository→Domain 계약 | endpoint, DTO, repository, 인증, cursor 작업 | Data 계층의 공통 규칙 변경 시 |
| [API_CONNECTION_STATUS.md](../API/API_CONNECTION_STATUS.md) | 전체 endpoint의 API Target·DTO·연결 여부, DTO 수와 정리 기준 | API 누락 점검, Swagger 변경 확인 | API 추가·변경·제거, DTO 연결 변경 시 같은 커밋에서 |
| [RELEASE.md](../Release/RELEASE.md) | Dev/Prod 환경, signing, TestFlight, privacy, analytics, 배포 검증 | Release archive, 배포, 개인정보, 환경 이슈 | 배포·환경·심사 절차 변경 시 |
| [VERSION_HISTORY.md](../Release/VERSION_HISTORY.md) | 배포 버전별 변경 내역과 패치노트 | 배포 준비, 버전 기능 확인 | 새 버전의 사용자 노출 변경이 확정될 때 |
| `Docs/Archive/*` | 과거 결정·사고·마이그레이션의 증거 | 사용자가 과거 사건/결정을 물을 때만 | MUST NOT 현재 정책·구현 규칙으로 사용. 기본 작업에서는 읽거나 수정하지 않음 |

## Project Skill

저장소는 UI 구현과 성능 조사에 필요한 project-local skill을 소유한다. skill은 프로젝트 구조 규칙의 원본이 아니며, `AGENTS.md`·활성 Docs·live code가 우선한다.

| Skill | 적용할 작업 | 먼저 읽을 것 | 적용하지 않는 작업 |
| --- | --- | --- | --- |
| `.agents/skills/rodi-swiftui` | SwiftUI View 구현·수정·리뷰, Figma UI 반영, UIKit bridge 화면 검토 | `AGENTS.md` → `Docs/Guides/UI_FIGMA.md`; 폴더/상태 변경이면 `Docs/Architecture/ARCHITECTURE.md`도 추가 | DTO/API만 변경, release, git, 문서만 작성, reducer-only 변경 |
| `.agents/skills/swiftui-expert-skill` | SwiftUI state·list·accessibility·navigation·performance 또는 Instruments trace 리뷰 | `AGENTS.md` → 관련 project Docs → 필요한 upstream reference | 일반 UI 구현, DTO/API, Git, 문서 작업 |
| `.agents/skills/ios-*-performance`, `.agents/skills/swift-*-performance` | launch, profiling, perceived latency, SwiftUI·concurrency·runtime 성능 조사 | `AGENTS.md` → 재현 증거·trace·관련 source → 필요한 skill reference | 측정 근거 없는 선제 최적화, 일반 기능 구현 |

외부 SwiftUI skill은 iOS 17+ `@Observable`, MVVM, generic system UI를 기본 권고할 수 있다. RODI에서는 iOS 16.1, ObservableObject, MVICore, Figma·design-system 계약을 MUST 우선한다.

### 외부 Skill 출처와 갱신

- `ios-*-performance`, `swift-*-performance` skill은 [Livsy90/iOS-Performance-Agent-Skills](https://github.com/Livsy90/iOS-Performance-Agent-Skills)의 commit `c259885045dd50f3a27b4df0eeab537b58799777`에서 project-local로 설치했다.
- `swiftui-expert-skill`은 [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill)의 commit `4c6a97d15aa5e023538c3cb06b5192f241dd451d`에서 project-local로 설치했다.
- MUST 외부 skill을 자동 갱신하지 않는다. 갱신 전 upstream diff, 라이선스, iOS 16.1·MVICore·Figma 규칙과의 충돌을 검토한다.

Codex runtime에서 제공하는 browser, Figma, 문서 등 외부 skill은 저장소의 영구 설계 규칙이 아니다. 해당 도구가 필요한 요청에서만 현재 세션의 지침을 읽어 적용하며, 이 문서에 변동 가능한 전체 목록을 복제하지 않는다.

## 작업 유형별 접근

### UI·Figma·SwiftUI

1. `AGENTS.md`, `UI_FIGMA.md`, 대상 Figma frame/screenshot, 대상 View·인접 Reducer를 읽는다.
2. token·asset·기존 Component를 검색해 재사용 여부를 먼저 결정한다.
3. View는 렌더링과 Action 전달만, Reducer는 상태·Effect만, SDK/외부 I/O는 Service·Adapter에 둔다.
4. selectable row/card/container는 전체 사각 영역을 `Button`과 `contentShape(Rectangle())`로 탭 가능하게 만든다.
5. iOS 16.1, safe area, keyboard, loading/empty/error/success, 긴 한국어 문구와 접근성을 검토한다.
6. Swift 변경이면 Dev Debug build와 `git diff --check`를 실행한다.

### API·DTO·Repository

1. `AGENTS.md`, `Docs/API/API_SWAGGER.md`, `Docs/API/API_CONNECTION_STATUS.md`, 해당 Swagger endpoint와 인접 API Target을 확인한다.
2. method, path, 인증, query/body, wrapper, nullable, cursor, enum을 확인한다.
3. `API Target → DTO → RemoteDataSource → RepositoryImpl/Mapper → Domain protocol/model → Presentation` 순서로 연결한다.
4. 새·변경 endpoint는 연결 현황 문서에도 반영한다. field가 화면에서 아직 사용되지 않아도 DTO에서 Domain까지 유실 없이 전달할지 판단한다.
5. Swagger schema 부족·실제 응답 불일치는 추정으로 숨기지 않고 `서버 문서 보완 필요`로 기록한다.
6. Swift 변경이면 Dev Debug build와 `git diff --check`를 실행한다.

### 구조·폴더링·리팩토링

1. `AGENTS.md`, `Docs/Architecture/ARCHITECTURE.md`, 대상 Layer 문서, 대상 feature 파일·route·의존성 조립 지점을 확인한다.
2. 사용자 기능 변경과 구조 변경을 분리한다. 한 번에 Presentation 전체를 이동하지 않는다.
3. `PRESENTATION.md`의 리팩터링 트리거를 기준으로 경계 위반·과도한 flow 책임·중복 조립을 우선 해결한다.
4. 새 폴더는 실제 책임이 생길 때만 만든다. `Component`, `SubPage`, `Section`, `Model`, `Service`, `Adapter`의 의미를 섞지 않는다.
5. 파일 이동 뒤 filesystem-synchronized group, route, delegate, build를 확인한다.

### 버그 분석·수정

1. 재현 조건, 실제 로그, 관련 state/action/effect를 먼저 분리한다.
2. UI 현상이라도 View만 고치지 말고 Reducer의 상태 전이·취소·stale response·scene lifecycle을 확인한다.
3. 원인을 확인하기 전에는 동작을 넓게 바꾸지 않는다. 최소 수정 후 실패·빈 상태·재시도 경로를 함께 점검한다.
4. 민감정보·정확 좌표·토큰은 로그나 보고에 남기지 않는다.

### Release·심사·개인정보

1. `Docs/Release/RELEASE.md`를 기준으로 Dev/Prod base URL, bundle ID, signing, Firebase 설정, Debug code 제외를 점검한다.
2. Privacy Manifest, Privacy Label, 공개 정책, 실제 SDK·위치·분석 처리의 정합성을 확인한다.
3. Release archive와 TestFlight 실기기 흐름을 별도로 검증한다.

### 문서만 변경

1. 해당 주제의 live code와 기존 문서가 일치하는지 확인한다.
2. 일시적 handoff/TODO 문서는 만들지 않는다. 단, `AGENTS.md`의 `Handoff Rules`가 명시한 루트 `Handoff/` 개인 작업 기록은 durable 운영 문서로 유지한다.
3. 문서 전용 변경은 Xcode build가 필요 없지만 `git diff --check`, 링크·경로·민감정보를 점검한다.

## 모든 작업의 공통 마무리

1. 의도하지 않은 user 변경을 되돌리거나 섞지 않는다.
2. `git diff --check`를 실행한다.
3. source/structure 변경이면 `Rodi Dev` Debug build를 실행한다.
4. build, 정적 검사, 수동 검증을 구분해 보고한다. 테스트 target이 없으므로 테스트가 통과했다고 표현하지 않는다.
5. 변경한 문서의 링크·경로가 실제 파일과 일치하는지 확인한다.
