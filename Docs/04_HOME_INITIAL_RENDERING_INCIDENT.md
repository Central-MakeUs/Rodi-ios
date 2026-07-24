# 홈 초기 진입 목록·마커 무반응 장애 기록

## 1. 현상

일부 iOS 26 기기 및 iPhone SE 3rd 시뮬레이터에서 앱을 처음 홈으로 진입했을 때 아래 현상이 발생했다.

- 지도와 클러스터 또는 단일 마커는 표시된다.
- `목록열기` 버튼이 표시되지 않거나, 표시되어도 반응하지 않는다.
- 단일 코스 또는 주차장 마커를 탭하면 마커의 선택 상태는 바뀌지만 상세 바텀싯이 올라오지 않는다.
- `마이` 탭으로 이동했다가 다시 `홈` 탭으로 돌아오면 목록 버튼과 마커 상세 진입이 정상 동작한다.

이 문제는 인증 실패나 장소 API 응답 실패와 다르게, 첫 홈 마운트 시점에만 나타났고 화면을 다시 만들면 정상화되는 특징이 있었다.

## 2. 재현 환경

- 기기: iPhone SE 3rd generation Simulator
- OS: iOS 26.2
- 앱: Debug 빌드
- 진입 조건: 온보딩 완료 상태에서 앱을 종료한 뒤 홈으로 새로 진입

확인 흐름:

1. 앱 실행 후 홈 지도 표시를 기다린다.
2. `목록열기` 표시 여부와 탭 동작을 확인한다.
3. 클러스터를 탭해 지도를 확대한 뒤 단일 주차장 마커를 탭한다.
4. 상세 바텀싯 표시 여부를 확인한다.
5. 비교를 위해 `마이 → 홈`으로 재진입해 동일 동작을 다시 확인한다.

## 3. 상태 추적으로 확인한 사실

개발 중 임시 상태 추적 로그로 최초 진입과 `마이 → 홈` 재진입을 비교했다. 해당 로그는 원인 확인 후 제거했다.

최초 진입에서도 다음 상태 전파는 정상이었다.

1. `HomeRuntimeService`가 초기 지도 렌더 요청을 생성한다.
2. `HomeRuntimeEvent.shouldRenderMapChanged(true)` 이벤트가 발생한다.
3. `HomeView.handleRuntimeEvent`가 이벤트를 수신한다.
4. `HomeReducer`가 `state.map.shouldRender`를 `false → true`로 변경한다.

즉, 지도 렌더 요청과 Store 상태 변경 자체는 실패하지 않았다.

반면 목록 버튼은 다음 세 조건이 모두 참일 때만 렌더링된다.

```swift
bottomSheetState != .expanded
!hasSelectedBottomSheet
shouldRenderMap
```

문제 상태에서는 Store 내부의 `shouldRenderMap`이 이미 `true`여도, 이 조건을 계산하는 `HomeView` 최상위 레이어가 다시 계산되지 않았다. 따라서 화면은 최초 렌더 당시의 `shouldRenderMap == false` 상태를 계속 사용했다.

`마이 → 홈` 전환 때는 `HomeView` 인스턴스가 새로 만들어지며 최신 Store 상태를 기준으로 body가 다시 계산됐고, 그 결과 목록 버튼과 바텀싯이 정상 동작했다.

## 4. 직접 원인

초기 구조에서 지도는 `@ObservedObject`를 갖는 별도 레이어(`HomeMapLayer`)가 렌더링했지만, 다음 UI는 `HomeView` 부모의 계산 프로퍼티가 Store 상태를 간접적으로 읽는 방식이었다.

- `listButtonLayer`
- `bottomSheetLayer`
- 선택 상태와 시트 높이에 의존하는 오버레이 레이어

이 구조에서는 Store의 `@Published state`가 초기 마운트 직후 변경될 때, 지도 레이어는 갱신될 수 있어도 부모 레이어가 상태 변경을 놓칠 수 있었다. 그 결과 지도 마커의 SDK 선택 표시와 SwiftUI 바텀싯/목록 버튼의 상태가 서로 어긋났다.

또한 기존 `Store.send`는 `reducer.reduce(&state, ...)` 형태로 `@Published` 저장 프로퍼티를 직접 `inout` 변경했다. 이 방식은 특정 SwiftUI 런타임에서 상태 변경 알림의 전달을 불명확하게 만들 여지가 있었다.

## 5. 검토했지만 최종 해결책으로 사용하지 않은 가설

### 런타임 시작 순서 문제

초기 마운트 후 `Task.yield()`로 지도 런타임 시작을 지연하는 실험을 진행했다. 하지만 지연 후에도 Store는 `shouldRenderMap=true`로 정상 변경됐고, 부모 레이어가 재계산되지 않는 현상은 남아 있었다.

결론: 위치 콜백 또는 런타임 시작 순서가 직접 원인은 아니었다. 지연 코드는 최종 코드에서 제거했다.

### 부모 뷰 강제 갱신

`homeStore.objectWillChange`를 구독해 별도 `@State` 값을 증가시키는 실험도 진행했다. 이 방식은 불필요한 갱신 요청을 다수 만들었지만, 근본적인 관찰 구조를 개선하지 못했다.

결론: 강제 갱신은 유지하지 않는다. 상태를 실제로 사용하는 레이어가 Store를 직접 관찰해야 한다.

### 토큰 재발급 또는 마이페이지 API 의존

`/api/v1/members/me` 호출 후 정상화되는 것처럼 보인 사례가 있었지만, 핵심 재현에서는 장소 상세 API 이전에 목록 버튼과 바텀싯 자체가 갱신되지 않았다. 따라서 토큰 재발급이나 마이페이지 조회는 직접 원인이 아니다.

## 6. 최종 수정

### Store 상태를 재할당하도록 변경

`Store.send`에서 reducer가 변경한 로컬 상태를 다시 `state`에 대입한다.

```swift
func send(_ action: Action) {
    var nextState = state
    let effect = reducer.reduce(&nextState, with: action)
    state = nextState
    handleEffect(effect)
}
```

이 방식으로 `@Published state` 변경을 명시적으로 발생시킨다.

수정 파일:

- `Rodi/Core/MVICore/Store.swift`

### Home 최상위 레이어가 Store를 직접 관찰하도록 변경

`HomeStoreObservedContainer`를 추가하고, 지도·목록 버튼·바텀싯을 포함한 홈 최상위 `ZStack`을 이 컨테이너 안에 배치했다.

```swift
private struct HomeStoreObservedContainer<Content: View>: View {
    @ObservedObject var homeStore: StoreOf<HomeReducer>
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
```

이제 `state.map.shouldRender`, `state.bottomSheet`, `state.selection` 변경은 해당 레이어의 body 재계산으로 이어진다.

수정 파일:

- `Rodi/Presentation/Home/Views/HomeView.swift`

## 7. 재발 시 확인 순서

1. `HomeRuntimeService`가 `HomeRuntimeEvent.shouldRenderMapChanged(true)`를 발행하는지 확인한다.
2. `HomeReducer`의 `state.map.shouldRender`가 `true`로 바뀌는지 확인한다.
3. 홈 최상위 레이어가 `@ObservedObject`로 Store를 직접 관찰하는지 확인한다.
4. 지도 SDK의 마커 선택 상태와 SwiftUI 바텀싯 상태가 같은 Store에서 파생되는지 확인한다.

## 8. 최종 검증 결과

iPhone SE 3rd iOS 26.2 시뮬레이터에서 아래를 확인했다.

- 앱 최초 홈 진입 직후 목록 버튼 렌더 조건이 `true / true / true`로 갱신됨
- `목록열기` 버튼이 실제 화면에 표시됨
- 목록 버튼 탭 시 추천 목록 바텀싯이 열림
- 클러스터 탭 시 지도 확대 동작 확인
- 확대 후 단일 주차장 마커 탭 시 선택 마커와 주차장 상세 바텀싯 표시 확인

따라서 최초 진입에서만 목록 버튼과 마커 상세가 무반응이던 재현 경로는 해결됐다.

## 9. 재발 방지 원칙

- Store 상태를 화면에 사용하는 레이어는 해당 Store를 직접 `@ObservedObject`로 관찰한다.
- 초기 렌더 누락을 시간 지연, 강제 redraw, 임의 재시도로 덮지 않는다.
- 지도 SDK의 마커 선택 상태와 SwiftUI의 목록/바텀싯 상태는 같은 Store 상태에서 파생되도록 유지한다.
- 초기 진입과 탭 재진입을 모두 검증한다. 탭 재진입만 통과하는 경우 화면 재생성이 문제를 가리고 있을 수 있다.
