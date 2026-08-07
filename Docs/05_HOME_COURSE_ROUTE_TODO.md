# Home Course Route TODO

Home에서 코스 marker를 선택했을 때 지도 경로를 단계적으로 복원한다. 각 단계는 구현과 `Rodi Dev` 빌드가 통과한 뒤에만 완료 처리한다.

## Phase 1 — 코스 marker부터 지도 경로 overlay

- [x] 코스 marker 탭 시 `/places/{id}` 상세 조회
- [x] waypoint 기반 fallback 경로와 출발·경유·도착 marker 표시
- [x] Kakao 도로 경로 API 성공 시 fallback path 교체
- [x] 도로 경로 실패 시 fallback 경로 유지 및 snackbar 안내
- [x] 경로 표시 중 일반 course·parking·cluster marker 숨김
- [x] 최신 상세·도로 경로 요청만 State에 반영
- [x] `Rodi Dev` 빌드 검증

## Phase 2 — 코스 상세 바텀싯과 경로 해제

- [x] Legacy `CourseDetailBottomSheetReducer` 기반 코스 상세 바텀싯 이식
- [x] 바텀싯 닫기 시 경로 overlay와 선택 상태 해제
- [x] 경로 loading·fallback 상태를 상세 UI에 표시

## Phase 3 — 코스 진입 경로 통합

- [x] 검색 결과 코스 선택
- [x] 최근 검색 코스 선택
- [x] 추천 목록 코스 선택

## Phase 4 — 상세 기능 연동

- [ ] 경로 재시도 UI
- [ ] bookmark
- [ ] 외부 길안내 handoff

## Phase 5 — Legacy 정리

- [x] Legacy 경로 reducer와 중복 서비스 제거
- [x] Home 구조를 아키텍처 문서에 확정

## Phase 1 전제

- 1차에서는 코스 상세 바텀싯과 수동 경로 해제를 구현하지 않는다.
- 경로가 표시되는 동안 일반 marker는 숨긴다.
- 도로 경로를 받기 전에도 waypoint 연결선은 즉시 표시한다.
