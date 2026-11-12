# RODI AI 활용 기록

> 2026-09-05에 보존한 과거 회고 자료다. 현재 구현 계약이나 AI 작업 지침으로 사용하지 않으며, 회고 작성 요청에서 필요한 경우에만 당시 근거로 확인한다.

## 목적

이 문서는 RODI 개발에서 AI를 어떤 판단 보조 도구로 사용했는지, 사용자가 무엇을 결정했고 어떤 코드·검증 근거가 남았는지 축적한다. 포트폴리오, 기술 면접, 프로젝트 회고에서 실제 사례를 빠르게 찾는 용도다.

이 문서는 AI의 작업 지침이나 기능 명세의 원본이 아니다. 실제 구현 규칙은 `AGENTS.md`, Architecture·API·UI·Release 문서와 live code를 우선한다.

## 기록 원칙

- MUST 완료되었거나 재현 가능한 작업만 사례로 기록한다.
- MUST AI가 제안한 내용과 사용자가 최종 결정한 내용을 구분한다.
- MUST 대상 코드, 관련 문서, build·로그·수동 QA 같은 근거를 함께 남긴다.
- MUST NOT 토큰, 개인 정보, 정확한 좌표, 비공개 URL, 원문 로그를 기록한다.
- SHOULD 기술 난이도보다 문제의 맥락, 제약, 선택한 이유, 검증 결과를 먼저 쓴다.
- SHOULD 기능 하나당 기록 하나를 기본으로 하되, 같은 원인·같은 검증 흐름이면 하나의 사례로 묶는다.

## 공통 사례 템플릿

아래 템플릿을 기능 구현, 문제 해결, 디버깅, 문서화, 검증 방식 중 알맞은 항목에 추가한다.

```md
### [상태] 사례 제목

- 날짜 / 버전 / 브랜치:
- 분류: 기능 구현 | 문제 해결 | 디버깅 | 문서화 | 검증 방식 | 학습
- 문제 또는 목표:
- 제약: iOS 최소 버전, Figma, Swagger, 기존 구조, 개인정보 등
- AI 활용:
  - 탐색·비교·설계·코드 제안·리뷰·검증 중 AI가 맡은 보조 역할
- 사용자 판단:
  - 채택·보류·수정한 결정과 이유
- 구현 및 근거:
  - 관련 Feature/파일, API 또는 문서 경로
- 검증:
  - 정적 검사 / Debug build / 수동 QA / 실기기 / 서버 응답 확인
- 결과:
  - 해결 여부, 남은 한계, 후속 작업
- 포트폴리오 키워드:
```

`상태`는 `초안`, `검증 완료`, `보류`, `회고 필요` 중 하나를 사용한다. `검증 완료`는 실제 build 또는 수동 재현 결과가 있을 때만 사용한다.

## 기능 구현

AI는 Figma·Swagger·인접 구현을 함께 확인하고, 기존 MVI와 foldering 안에서 구현 후보를 좁히는 데 사용한다. 사용자는 기능 범위, UX 정책, API 계약의 최종 판단을 맡는다.

### 기록할 가치가 높은 사례

- Figma 화면을 `View → Action → Reducer → Effect → Service` 책임으로 나눈 구현
- Swagger DTO부터 Domain contract, Presentation까지 연결한 기능
- 후기 작성·수정, 신고·차단처럼 상태 단계와 실패·재시도 흐름이 있는 기능
- 코스 상세, 지도, 바텀시트처럼 기존 화면·SDK·safe area 제약을 유지한 기능
- Live Activity, 외부 길안내, 위치 권한처럼 시스템 API와 앱 상태가 함께 움직이는 기능

작성 대기 중인 포트폴리오 후보와 필요한 검증은 [TODO](../../TODO.md)의 `WRITE` 항목에서 관리한다. 이 문서에는 근거가 확보된 실제 사례만 추가한다.

## 문제 해결

문제 해결 기록은 증상만 적지 않고, 원인 가설을 어떻게 좁혔고 왜 다른 해결책을 제외했는지를 남긴다.

### 기록할 가치가 높은 사례

- 위치 권한을 설정 앱에서 변경한 뒤 foreground 복귀 시 상태가 갱신되지 않는 문제
- custom bottom sheet의 drag·safe area·앱 전환 복귀에서 발생하는 레이아웃 문제
- 후기·검색·목록의 중복 요청과 늦은 응답이 종료된 화면을 다시 갱신하는 문제
- API DTO와 실제 Swagger 응답 불일치로 발생한 decoding 실패
- 키보드, 긴 텍스트, compact 기기에서 생기는 SwiftUI layout 문제

### 작성 기준

- MUST 증상, 재현 조건, 원인, 수정 범위, 회귀 위험을 구분한다.
- SHOULD “AI가 해결했다”보다 AI가 제시한 가설·검색 범위·대안 비교를 쓰고, 최종 수정 근거는 코드와 검증으로 제시한다.

## 디버깅

AI는 로그·State·Action·Effect 흐름을 따라 재현 경로를 좁히고, 민감값이 없는 진단 로그와 breakpoint 위치를 제안하는 데 사용한다.

### 기록할 가치가 높은 사례

- `isSuccess == true`인데 mapper 또는 상태 전이에서 실패로 처리된 API 흐름
- stale response, request revision, cancellation ID로 해결한 재진입·이탈 문제
- SDK callback과 Swift concurrency 경계에서 발생한 중복·누락·timeout 문제
- 서버 오류 코드(401/403/409, decoding failure)를 사용자 feedback과 내부 진단으로 분리한 사례

### 기록 기준

- MUST 로그에는 endpoint·오류 종류·안전한 상태만 기록하고 토큰·credential·정밀 좌표·원문 응답은 제외한다.
- MUST breakpoint, 로그, 서버 응답, UI 상태 중 실제로 사용한 증거를 명시한다.
- SHOULD 재현이 어려운 문제는 기기·iOS·권한·네트워크·앱 lifecycle 조건을 함께 적는다.

## 문서화

AI는 반복되는 판단을 줄이기 위해 프로젝트 규칙을 짧은 원본 문서로 정리하고, 문서와 코드가 달라질 때 정합성 후보를 찾는 데 사용한다.

### 기록할 가치가 높은 사례

- `AGENTS.md`의 최소 컨텍스트 router와 보안·iOS 16.1·보호 영역 규칙
- Architecture의 Layer 계약과 Feature foldering 기준
- Figma·Swagger·Release 문서의 작업별 원본 분리
- Architecture 규칙과 TODO 작업 상태를 분리한 사례

### 작성 기준

- MUST 문서가 live code·Swagger·Figma를 대체한다고 주장하지 않는다.
- SHOULD 문서가 줄인 반복 판단, 예방한 위험, 갱신 시점을 함께 적는다.

## 검증 방식

AI는 구현 뒤 검증 항목을 누락하지 않도록 체크리스트를 만들고, build·정적 검사·수동 QA의 결과를 분리해 기록하는 데 사용한다.

### 기본 검증 흐름

1. 정적 확인: 관련 심볼·경로·DTO·문서 링크·민감정보·`git diff --check`
2. Dev Debug build: iOS 16.1 deployment target을 포함한 컴파일 확인
3. 수동 QA: loading·empty·error·success, 빠른 연속 탭, 이탈·재진입, 권한·네트워크 단절
4. 필요 시 실기기·Release/TestFlight: 위치, Kakao/Apple 로그인, 지도, 외부 앱 복귀, Live Activity

### 작성 기준

- MUST build 성공과 수동 QA 완료를 같은 의미로 쓰지 않는다.
- MUST 실행하지 않은 자동 테스트를 통과했다고 기록하지 않는다.
- SHOULD 확인하지 못한 기기·OS·외부 앱 상태는 한계로 남긴다.

## 학습 (선택)

현재 학습 활동을 별도 성과로 기록하지 않는다. 다만 실제 구현·리뷰·회고를 통해 이해한 내용이 생기면 아래 형식으로 추가한다.

```md
### [검증 완료] 학습 주제

- 계기: 어떤 구현 또는 버그에서 필요해졌는가
- 배운 개념: 예) MVI child reducer, actor isolation, SwiftUI identity, UIKit delegate lifecycle, HTTP decoding
- 코드 근거: 어떤 파일·변경에서 적용했는가
- 검증: 적용 전후 어떤 동작을 확인했는가
- 다음 적용: 어느 Feature에서 재사용할 수 있는가
```

취업·포트폴리오 관점에서는 일반적인 기술 요약보다, 실제 코드의 제약 아래에서 어떤 선택을 했는지 설명할 수 있는 학습만 기록한다.

## 협업

현재 실제 협업 사례를 기록하지 않는다. Figma handoff, Swagger 계약 조율, Android 동기화, QA 재현 전달처럼 외부 구성원과 확인한 사실이 생겼을 때만 위 공통 템플릿으로 추가한다.
