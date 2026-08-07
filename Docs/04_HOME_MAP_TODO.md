# Home Map TODO

Home에서 지도 기능을 단계적으로 구현한다. 추천 목록 BottomSheet는 지도 viewport/research command 계약으로만 연결되며, BottomSheet 자체의 UI·목록 state는 별도 feature가 소유한다.

## 지도 기본 흐름

- [x] `mapActivationRequested`
- [x] `mapBecameReady`
- [x] 지도 State를 `HomeReducer.State.MapState`로 분리
- [x] 의존성 주입
- [x] `MapService` 위치·좌표 I/O 모듈화 및 `HomeReducer` State 소유
- [x] `MapLocationService`·`MapMarkerRenderingService` 명칭 및 책임 정리
- [x] 위치 확인 실패 snackbar View 브리지

## 현재 위치

- [x] 최초 위치 서비스와 권한/실패 상태
- [x] 현재 위치 수신 시 카메라·사용자 위치 반영
- [x] 위치 권한 거절 안내 UI
- [x] 현재 위치 버튼과 명시적 재요청

## 장소 마커

- [x] 장소 좌표 API 조회
- [x] 단순 마커 변환·렌더링
- [x] 마커 로딩 실패 State
- [x] 마커 로딩 실패 재시도 UI

## 이후 지도 기능

- [x] 지도 이동·줌 이벤트
- [x] 클러스터링과 점진 렌더링
- [x] 클러스터 탭 카메라 이동
- [x] 코스·주차장 마커 탭
- [x] 지도 lifecycle 중지·재진입 정책

## BottomSheet 연결 경계

- [x] `HomeReducer.State.bottomSheet`과 `.bottomSheet(...)` child reducer 합성
- [x] Map viewport·최초 위치·재검색 버튼 → 추천 목록 Action 직접 전달
- [x] 추천 목록·지도 marker 선택 → BottomSheet 상세 resolve와 Map focus 연결
- [x] 코스·주차장 실제 상세 BottomSheet, route overlay, dismiss Delegate 이식

## 클러스터 탭 정책

- Legacy 기준 tier를 사용한다: 광역 `≤8`, 시·군·구 `9...11`, 개별 marker `≥12`.
- cluster 탭은 다음 tier marker 좌표의 영역을 fitting한다. 분포가 넓으면 줌아웃될 수 있다.
- 다음 tier의 강제 표시는 사용자가 직접 지도 zoom을 바꿀 때까지 유지한다.
