# RODI Dev And Prod Environment Strategy

이 문서는 Rodi의 개발 환경과 운영 환경을 분리하기 위한 구현 기준이다. 현재는
설계 문서만 제공하며, Xcode 설정, Fastlane, 외부 콘솔, 앱 코드는 이 문서로 인해
변경되지 않는다.

## 1. Environment Contract

Rodi는 당분간 아래 두 환경만 공식적으로 운영한다.

| 구분 | Dev | Prod |
| --- | --- | --- |
| 목적 | 개발, QA, Internal TestFlight | App Store 및 운영 사용자 |
| 앱 식별자 | `com.dororong.rodi.dev` | `com.dororong.rodi` |
| 앱 표시명 | `Rodi Dev` | `Rodi` |
| 배포 | Xcode, Internal TestFlight | TestFlight, App Store |
| API | 운영 API 공유 | 운영 API |
| 계정 | 전용 Kakao/Apple 테스트 계정 | 운영 사용자 계정 |
| App Store 업데이트 검사 | 비활성 | 활성 |
| Firebase/Clarity | 추후 Dev 프로젝트 | 추후 Prod 프로젝트 |

`Staging`과 개발자별 local server는 이번 환경 정책에 포함하지 않는다. 운영 API를
공유하는 동안 Dev는 테스트 계정과 테스트 데이터만 사용한다.

## 2. Build Architecture

앱 타깃을 복제하지 않고 `Rodi` 단일 타깃과 환경별 Configuration/Scheme을 사용한다.

| Configuration | 목적 | Scheme |
| --- | --- | --- |
| `DevDebug` | Xcode 로컬 개발 및 디버깅 | `Rodi Dev` |
| `DevRelease` | Internal TestFlight 품질 검증 | `Rodi Dev Release` |
| `ProdRelease` | 운영 TestFlight 및 App Store 배포 | `Rodi` |

공통 코드는 하나로 유지한다. bundle ID, 표시명, App Icon, API URL, App Store ID,
분석 키, 로그 정책처럼 환경에 따라 달라지는 값만 build setting과 xcconfig로 주입한다.

Dev는 운영 앱과 같은 기기에 설치할 수 있어야 한다. Dev icon에는 눈에 띄는 개발용
표시를 넣어 운영 앱 오조작을 막는다.

## 3. Configuration And Secrets

설정은 공통값, 환경별 비밀이 아닌 값, 로컬/CI 비밀값의 세 계층으로 분리한다.

```text
Config/
├── Shared.xcconfig                 # Git 추적: 모든 환경 공통 키 선언
├── Dev.xcconfig                    # Git 추적: Dev 환경값과 local include
├── Prod.xcconfig                   # Git 추적: Prod 환경값과 local include
├── Secrets.dev.local.xcconfig      # Git ignore: Dev 비밀값
├── Secrets.prod.local.xcconfig     # Git ignore: Prod 비밀값
└── Secrets.example.xcconfig         # Git 추적: 비어 있는 키 템플릿
```

환경별로 최소한 다음 값을 주입한다.

| Key | Dev | Prod |
| --- | --- | --- |
| `RODI_ENVIRONMENT` | `dev` | `prod` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.dororong.rodi.dev` | `com.dororong.rodi` |
| `PRODUCT_DISPLAY_NAME` | `Rodi Dev` | `Rodi` |
| `RODI_API_BASE_URL` | 운영 URL을 명시 | 운영 URL을 명시 |
| `APP_STORE_APP_ID` | 비움 | 운영 App Store ID |
| `KAKAO_NATIVE_APP_KEY` | Dev 허용 key | Prod key |
| `KAKAO_REST_API_KEY` | Dev key 또는 승인된 공용 key | Prod key |
| Firebase/Clarity 설정 | 추후 Dev 값 | 추후 Prod 값 |

`AppEnvironment` 같은 단일 구성 진입점이 bundle 설정을 읽는다. View, Reducer,
Repository가 문자열 비교로 환경을 판단하지 않는다. API URL도 현재의 fallback에
의존하지 않고 각 환경에서 명시한다.

다음은 Git에 절대 포함하지 않는다.

- `Secrets.*.local.xcconfig`
- App Store Connect `.p8` 키
- Firebase `GoogleService-Info.plist`의 실제 환경 파일
- Clarity project ID 또는 환경별 secret

기존 `Config/Secrets.local.xcconfig` 사용자는 환경별 local secret으로 옮긴 뒤
삭제한다. 템플릿에는 실제 값을 넣지 않는다.

## 4. Product-Specific Behavior

### Version Update

- `ProdRelease`만 App Store 버전 조회와 업데이트 안내를 실행한다.
- Dev는 별도 App Store 앱 ID를 조회하거나 운영 앱의 강제 업데이트를 표시하지 않는다.
- `RootReducer`의 앱 버전 검사 시작 여부는 `AppEnvironment.isProduction`으로 한 곳에서
  결정한다.

### Session And Local Storage

- 서로 다른 bundle ID를 사용하므로 UserDefaults와 기본 Keychain 영역은 Dev/Prod에서
  분리된다.
- Keychain access group 또는 App Group을 새로 추가하지 않아 Dev/Prod 토큰이 공유되지
  않게 한다.
- Dev에서는 전용 테스트 계정만 사용한다. 운영 API 공유 상태에서 운영 계정의 탈퇴,
  복구, 북마크, 필터, 온보딩을 검증 대상으로 사용하지 않는다.

### Logging

- Dev는 문제 분석에 필요한 구조화 로그를 허용한다.
- 모든 환경에서 OAuth credential, access/refresh token, Kakao key, 정확한 위도·경도는
  로그에 남기지 않는다.
- Prod는 기존 Release 로그 제한을 유지한다.

## 5. External Platform Setup

환경 Configuration을 만들기 전에 아래 콘솔 등록을 완료한다.

### Apple Developer And App Store Connect

1. Apple Developer에 `com.dororong.rodi.dev` App ID를 만든다.
2. Dev App ID에 Sign in with Apple capability를 활성화한다.
3. Prod와 Dev에서 Apple 사용자 식별 정책이 필요한 경우 App ID grouping을 검토한다.
4. App Store Connect에 `Rodi Dev`를 별도 앱 레코드로 만들고 Internal TestFlight만
   사용한다. 공개 배포와 외부 테스터 배포는 하지 않는다.
5. 기존 `Rodi` App Store Connect 레코드는 Prod 배포만 담당한다.

### Kakao Developers

1. Dev bundle ID를 Kakao iOS platform 허용 목록에 등록한다.
2. 동일 Kakao 앱에서 여러 bundle ID를 지원하면 승인된 같은 Native App Key를 사용한다.
3. 지원하지 않거나 인증 흐름 분리가 필요하면 Dev Kakao 앱을 새로 만들고 Dev key를
   발급한다.
4. Dev 실기기에서 KakaoTalk 로그인, 웹 로그인, Kakao Map SDK, KakaoNavi 호출을 각각
   검증한다.

## 6. Fastlane Delivery Policy

Fastlane은 환경을 명시한 lane만 제공한다. 기본 lane이나 암묵적 Debug/Release 선택으로
업로드하지 않는다.

| Lane | Scheme / Configuration | 대상 |
| --- | --- | --- |
| `dev_beta` | `Rodi Dev Release` / `DevRelease` | Rodi Dev Internal TestFlight |
| `prod_beta` | `Rodi` / `ProdRelease` | Rodi 운영 TestFlight |
| `prod_release` | `Rodi` / `ProdRelease` | App Store 제출 |

각 lane은 archive 전 bundle ID, configuration, App Store Connect app ID를 검증한다.
서로 다른 App Store Connect 레코드이므로 Dev와 Prod build number는 독립적으로
증가한다. Prod release lane은 Dev bundle ID 또는 Dev configuration이면 즉시 실패해야
한다.

## 7. Operations With Shared Production API

운영 API를 공유하는 현재 선택은 비용과 운영 복잡도를 낮추지만, Dev 데이터가 서버에
실제로 남는다는 뜻이다.

- Kakao/Apple 전용 테스트 계정을 만들고 담당자와 용도를 기록한다.
- 테스트 계정으로 만든 북마크, 운전 목표, 필터, 탈퇴 상태는 테스트 후 정리한다.
- 탈퇴·복구·재가입 제한은 테스트 계정을 순환해 운영하고, 일반 QA 계정으로 반복하지
  않는다.
- 검색·지도·장소 조회는 읽기 중심이므로 전용 계정으로도 충분히 검증한다.
- 테스트가 잦아져 운영 데이터 오염, 상태 충돌, 서버 장애 재현 문제가 커지면 Dev API와
  DB 분리를 최우선 후속 작업으로 승격한다.

## 8. Analytics And Observability Follow-Up

환경 기반이 완료된 후에만 Firebase와 Clarity를 연결한다.

- Firebase Dev 프로젝트: DebugView, Crashlytics, Performance 검증 전용.
- Firebase Prod 프로젝트: 실제 운영 분석과 장애 관찰 전용.
- Clarity는 Prod부터 적용하며, 민감 화면 마스킹과 법무 문서·App Store Privacy Label
  갱신을 선행한다.
- 상세 이벤트와 수집 금지 항목은
  [05_ANALYTICS_AND_OBSERVABILITY_PLAN.md](05_ANALYTICS_AND_OBSERVABILITY_PLAN.md)를
  따른다.

## 9. Implementation Order

1. 환경 표와 테스트 계정 운영자를 확정한다.
2. Apple Developer, App Store Connect, Kakao Developers의 Dev 등록을 끝낸다.
3. xcconfig 계층과 ignored local secret 템플릿을 만든다.
4. `DevDebug`, `DevRelease`, `ProdRelease` Configuration과 세 Scheme을 만든다.
5. bundle ID, display name, App Icon, URL scheme, App Store update check를 환경별로
   주입한다.
6. Dev/Prod 인증·지도·길안내·세션 분리를 실기기로 검증한다.
7. Fastlane Dev/Prod lane과 archive guard를 추가한다.
8. Internal TestFlight Dev 업로드와 Prod TestFlight 업로드를 각각 검증한다.
9. 환경 경계가 안정화된 뒤 Firebase/Crashlytics/Performance/Clarity를 별도 작업으로
   연결한다.

## 10. Acceptance Checklist

- [ ] Dev와 Prod 앱이 같은 기기에 동시에 설치된다.
- [ ] 이름, icon, bundle ID, UserDefaults, Keychain 로그인 상태가 분리된다.
- [ ] DevDebug, DevRelease, ProdRelease가 각 환경의 명시된 값을 가진다.
- [ ] Dev는 App Store 업데이트 안내를 표시하지 않는다.
- [ ] Dev와 Prod의 Kakao/Apple 로그인, 지도, 길안내가 각각 실기기에서 동작한다.
- [ ] `dev_beta`는 Dev Internal TestFlight에만, `prod_beta`/`prod_release`는 운영 앱에만
  업로드된다.
- [ ] 실제 시크릿·`.p8`·환경별 Firebase/Clarity 파일이 Git 추적과 Git 이력에 없다.
- [ ] Firebase/Clarity 도입 전에는 해당 SDK나 Privacy Label 변경을 포함하지 않는다.
