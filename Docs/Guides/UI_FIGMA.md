# RODI UI · Figma Guide

## 목적과 적용 범위

이 문서는 Figma node를 근거로 RODI UI를 구현하거나 검토할 때 디자인 근거를 수집하고 차이를 판정하는 절차를 정의한다.

- MUST Figma 링크만 전달된 설명·분석 요청과 실제 구현 요청을 구분한다. 링크 자체를 파일 수정 권한으로 해석하지 않는다.
- MUST UI의 시각 계약은 대상 node의 screenshot과 속성으로, 현재 기능 동작은 live code로 확인한다.
- MUST 선택된 chip이나 비활성 button 한 상태만 보고 단일·복수 선택, 필수 입력, API 호출 같은 기능 정책을 추정하지 않는다.
- SHOULD Reducer 소유권이나 foldering 변경이 필요할 때만 [ARCHITECTURE.md](../Architecture/ARCHITECTURE.md)를 추가로 읽는다.

## Figma 근거 확인

1. MUST URL에서 구현 대상 `node-id`를 확인하고, 현재 실행 환경의 필수 Figma 지침을 읽는다.
2. MUST 대상 node의 design context와 screenshot을 확인한다. 생성된 React·Tailwind는 hierarchy·문구·asset 단서로만 사용한다.
3. MUST device bezel, status bar, home indicator 같은 기기 chrome을 앱 asset이나 custom View로 옮기지 않는다.
4. MUST 같은 작업에서 이미 확인했고 변경되지 않은 node를 반복 조회하지 않는다. 결과 누락·잘림·디자인 변경·별도 상태 확인이 필요할 때만 추가 조회한다.
5. MUST context를 얻지 못한 page·canvas node라면 내부의 실제 frame을 찾아 다시 조회한다.

## 기존 구현 탐색과 차이 판단

- MUST 기존 화면 수정이면 화면 고유 문구나 예상 심볼을 `rg -l`로 검색하고, 대응 View와 직접 사용되는 Component부터 읽는다.
- MUST 신규 화면이면 인접 Feature의 실제 진입 경로와 가장 유사한 화면을 확인한다. 기존 화면이 있다는 전제로 검색 결과를 해석하지 않는다.
- MUST 화면 구조, interaction, navigation, loading·empty·error·success 상태를 구분하고 Figma에 없는 동작은 live code나 명시된 제품 요구사항으로 확인한다.
- MUST NOT Figma, 사용자 요구사항, live code에서 확인할 수 없는 화면·상태·상호작용을 임시 UI나 임의의 정책으로 구현한다.
- MUST 구현 근거가 없는 부분을 현재 범위에서 제외하고, 무엇이 미구현으로 남았는지 결과에 명시한다.
- MUST Plan Mode에서 구현 근거가 없는 부분을 발견하면 계획을 확정하기 전에 임시 구현 여부와 동작 범위를 사용자에게 질문한다. 사용자의 명시적 동의가 없으면 임시 구현을 계획에 포함하지 않는다.
- MUST 사용자가 임시 구현을 명시적으로 선택한 경우에만 제품 구현과 구분되는 범위로 격리하고, 임시 구현의 근거·제거 조건·미검증 사항을 결과에 명시한다.
- MUST Figma와 현재 구현이 다르면 시각 변경, 기능 변경, 서버 계약 변경을 구분한다. 현재 코드를 근거로 디자인 계약을 자동 변경하지 않는다.
- SHOULD 후보 파일을 좁힌 뒤 필요한 심볼과 구간만 읽고, 변경 위치·유지할 계약·검증 방법이 확정되면 탐색을 멈춘다.

### 구현 전 근거 판정

- MUST 새 화면·여러 상태·CRUD 연결을 계획할 때 요소별로 `확정`, `미확정`, `제외`와 근거를 구분한다. `확정`에는 Figma node, 기존 코드 또는 사용자 결정 중 실제 근거를 붙인다.
- MUST 미확정 사항 중 동작·디자인·데이터 계약을 바꾸는 결정은 질문하고, 답변 전에는 해당 구현을 진행하지 않는다. 이미 승인된 범위는 재승인을 요청하지 않는다.
- MUST NOT 목업 데이터 사용 승인을 임의의 선택창·확인 팝업·오류 문구·검증 조건 또는 요청하지 않은 CRUD 동작의 승인으로 해석한다. 원본 에셋이 없는 경우도 같은 기준을 적용한다.
- SHOULD 근거 판정은 현재 계획이나 진행 보고 안에 짧게 남긴다. 단순 수치 수정에 표를 강제하거나 별도 문서를 만들지 않는다.

| 요소 예시 | 판정 | 근거 또는 다음 결정 |
| --- | --- | --- |
| 카드·catalog에 없는 아이콘 | 확정 | 대상 node의 속성·원본 export |
| 날짜 행을 누른 뒤 선택창 | 미확정 | 후속 디자인 또는 임시 구현 여부·범위 확인 |
| 서버 저장 | 제외 | 현재 요청은 메모리 목업 목록만 연결 |

## Token·Component·Asset 적용

- MUST RODI의 token·Component·custom UI 계약은 `.agents/skills/rodi-swiftui`에서 확인하고, 같은 의미의 기존 구현을 우선 사용한다.
- MUST 새 token이나 공통 Component는 현재 요청에서 실제 중복이나 공유 책임이 확인된 경우에만 추가한다.
- MUST 단순 UI 변경을 캐싱·성능 최적화·공통 Component 개편으로 확대하지 않는다.
- MUST asset 재사용 여부를 이름만으로 판단하지 않고 glyph, 크기, 투명 여백, rendering mode를 Figma export와 대조한다.
- MUST 없는 asset은 Figma가 제공한 원본 bytes를 의미 기반 이름으로 catalog에 추가한다. 임시 asset URL이나 임의로 다시 그린 대체물을 source에 남기지 않는다.
- MUST export된 도형만 포함하는지 바깥 component frame까지 포함하는지 확인하고, 도형 크기·배치 영역·터치 영역을 구분한다.
- MUST 파일 이름과 실제 glyph 방향을 각각 확인하고, 부모 frame의 회전·반전·crop이 export 결과에 포함됐는지 대조한다.
- MUST 터치 영역을 넓히기 위해 image 자체를 확대하지 않는다.
- MUST 원본 image의 resize·재압축과 View의 표시 크기 조절을 구분하고, 원본 bytes를 바꿨다면 결과에 명시한다.
- SHOULD 같은 원본 node에서 사용하는 관련 asset의 크기·방향·여백을 한 번에 대조한다.
- MUST Figma 문구가 안전·사고 방지를 보장하면 `AGENTS.md`의 제품 안전 제약에 맞춰 처리한다.

## 레이아웃 판정

- MUST Figma의 x·y 좌표나 viewport 크기를 화면 전체 고정 frame과 `.position`으로 복제하지 않는다.
- MUST `GeometryReader`, 측정용 `PreferenceKey`, 직접 `UIScreen.main`, 반복적인 `.offset`을 일반적인 화면 배치 수단으로 사용하지 않는다.
- SHOULD stack, grid, scroll, alignment, flexible frame, safe-area API와 기존 project abstraction 순서로 적응형 구조를 선택한다.
- MUST 측정 API가 필요하면 기존 UI 계약과 SDK·gesture 제약으로 대체할 수 없는 이유와 영향 화면을 확인한다.
- MAY 명확한 icon·Component 자체 크기와 장식 목적의 제한된 위치값은 고정할 수 있다.

## 검증과 보고

- MUST 변경 영향에 맞춰 hierarchy, spacing, typography, color, corner, asset, selected·disabled·error 상태와 interaction을 확인한다.
- MUST 신규 화면·입력·scroll 변경에서는 compact·large device, safe area, keyboard, 긴 한국어 문구, Dynamic Type, VoiceOver tap target을 확인한다.
- SHOULD 동일 상태의 screenshot을 Figma와 나란히 비교하고 의도적으로 다른 부분과 확인하지 못한 상태를 보고한다.
- MUST 코드·구조 변경 뒤 `AGENTS.md`의 Dev Debug build를 실행한다. 자동 테스트를 실행하지 않았다면 테스트 통과로 보고하지 않는다.
- MUST 단순 색상·간격 변경과 신규 interaction 화면에 동일한 전체 QA 목록을 기계적으로 적용하지 않는다.
