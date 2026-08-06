# Home Search TODO

Home Search는 `HomeReducer`가 child State와 Action을 합성하고, `HomeSearchReducer`가 최종 Delegate로 지도·바텀싯·공통 presentation에 필요한 결과만 부모로 전달한다.

## Legacy Search 이식

- [x] Search UI 컴포넌트를 `Presentation/Home/Search/Component`에 정식 이식
- [x] `HomeSearchReducer`에 실시간 연관 검색, 지역 검색, 최근 검색, 페이지네이션 이식
- [x] View callback·직접 `SnackbarService` 의존을 최종 Delegate로 교체

## Home 연결

- [x] `HomeReducer.State.search`와 `.search(HomeSearchReducer.Action)` 합성
- [x] 지도 검색 진입 버튼과 시스템 full-screen cover 연결
- [x] 검색 장소 선택 → BottomSheet place resolve → 지도 포커스·상세 표시 연결
- [x] 검색 dismiss 및 Snackbar presentation Delegate 연결

## 검증 및 후속

- [ ] 지역 선택·최근 검색·연관 장소·페이지네이션 동작 확인
- [ ] 검색 결과 선택 후 코스·주차장 상세와 지도 포커스 확인
- [ ] 검색 State 유지 정책과 full-screen dismiss 동작 확인
- [x] `Rodi Dev` 빌드 검증
- [x] Legacy Search 중복 타입과 `2` 접미사 정리

## 경계 규칙

- `HomeReducer`는 Search State를 렌더링과 child reducer 실행에만 사용한다.
- Search 내부 Action·State를 읽어 지도 또는 BottomSheet 흐름을 판단하지 않는다.
- `HomeSearchReducer.Delegate`의 장소 선택·dismiss·snackbar 요청만 부모가 해석한다.
