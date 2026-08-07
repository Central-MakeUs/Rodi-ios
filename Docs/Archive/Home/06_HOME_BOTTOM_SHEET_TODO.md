# Home BottomSheet TODO

Home의 BottomSheet는 `HomeReducer`가 child State와 Action을 합성하고, `HomeBottomSheetReducer`가 하위 delegate를 최종 Delegate로 평탄화해 Map·presentation 교차 흐름을 중재한다.

## Legacy BottomSheet 복귀

- [x] BottomSheet 트리를 `Presentation/Home/BottomSheet` 정식 경로로 이식
- [x] 별도 Store, Input, Intent, Envelope 구현 제거
- [x] `HomeReducer.State.bottomSheet`과 `.bottomSheet(HomeBottomSheetReducer.Action)` 합성
- [x] 최종 BottomSheet Delegate 기반 Map·탭바·인증·Snackbar 중재

## 연결된 BottomSheet 흐름

- [x] viewport, 최초 위치, 재검색 버튼 → 추천 목록 Action 전달
- [x] 추천 카드·지도 marker → 장소 상세 resolve 흐름 통합
- [x] 필터 적용·dismiss → 추천 목록 재조회·표시 복귀
- [x] 코스 route overlay·dismiss·bookmark Delegate → Map/presentation 반영
- [x] 주차장 focus·dismiss·bookmark Delegate → Map/presentation 반영
- [x] `Rodi Dev` 빌드 검증

## BottomSheet 복구

- [x] 추천 목록을 Legacy custom overlay로 복귀하고 View-local settle로 50%/전체 높이 전환
- [x] `screenBounds` 환경값을 통한 화면 높이 기준 통일
- [x] 확장 추천 목록을 화면 전체 white overlay와 top safe-area header(뒤로가기·필터)로 구성
- [x] 초기 추천 목록 접힘 및 목록열기 버튼·탭바 동시 노출
- [x] 수동 재검색 성공 시 최신 viewport 결과를 중간 높이 목록으로 표시
- [x] 코스 intrinsic 높이·필터/주차장 50% 고정·route별 드래그 규칙 복구
- [x] 코스·주차장 dismiss의 추천 목록 접힘과 탭바 복귀를 원자 전이로 처리
- [x] `Rodi Dev` 빌드 검증
- [ ] iPhone 12 Pro 실기기 화면 확인

## 후속

- [x] Search를 `HomeReducer.State.search`와 `.search(HomeSearchReducer.Action)` 합성으로 이식
- [x] 검색 결과·최근 검색을 BottomSheet resolve 흐름에 통합
- [ ] deep-link를 BottomSheet resolve 흐름에 통합
- [x] Legacy 표기와 중복 파일 정리

## 경계 규칙

- `HomeReducer`는 BottomSheet State를 렌더링과 child reducer 실행에만 사용한다.
- `HomeBottomSheetReducer`가 하위 delegate를 내부 처리하고, Map·Search·BottomSheet 교차 판단은 최종 `HomeBottomSheetReducer.Delegate` payload만으로 수행한다.
- 별도 Input, CommandPort, Relay, Coordinator, Envelope를 만들지 않는다.
