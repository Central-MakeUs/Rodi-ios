# 윤달 HandOff

## Current

- 기준 저장소·브랜치: 현재 작업 저장소의 `dev`
- 기준 커밋: `416cefa5a34e9441280e456fd1405fd47e04e1c9`
- 작성일: 2026-09-05
- 현재 작업: 활성 작업 문서 정비와 AI 탐색 범위 개선

## Recent Work
- 브랜치: `refactor/1.4.4-live-activity`
- 구현 탐색 백로그의 주행 경험에 코스 진입·완료 시 로컬 알림을 한 번 표시하는 후속 기능을 추가했다.
- 작업 상태: `main`과 `dev`를 `93f5d7c`으로 동기화한 뒤 Kakao Map adapter 통합·평가 문서 변경을 분리 커밋했다. Rodi Dev Debug build 성공, 일부 XCTest 크래시 원인 확인 대기.
- 연습 측정 복귀 정책 reducer 병합과 위치 런타임·인증 재시도 분리를 완료했다. 실제 외부 길안내·백그라운드 수동 QA가 다음 작업이다.
- App Switcher 강제 종료 직전 Live Activity 정리와 콜드 런치 고아 Activity 정리를 구현했다. iOS 16.1 이상 실기기 강제 종료 QA가 남아 있다.
- Live Activity의 생명주기·상태 변환·갱신 정책·Debug 프리뷰·Widget UI 책임을 분리했다. 코드 기반 기술 블로그 작성과 실기기 UI·종료 흐름 QA가 다음 작업이다.
- Notion의 Live Activity 기술 블로그 초안에서 Dynamic Island·갱신 정책·종료 정책·iOS 16.1 fallback 설명을 현재 코드 기준으로 퇴고했다. 사진 출처 표기와 다음 코스 판정 목차 작성이 남아 있다.
- Notion 기술 블로그의 Core Location·Live Activity·코스 판정 설명과 마치며를 현재 구현 기준으로 정리했다. 실주행 검증 목차는 제외하고 임계값을 검증 전 초기 기준으로 명시했다.

## Recent Work
- 기술 블로그에서 실주행 검증 목차와 결과표를 제거했다. 60m·150m·40%/5km·GPS 점프 기준은 오판을 줄이기 위한 초기값이며 정량적으로 검증한 최종값이 아님을 본문과 마치며에 명시했다.
- 기술 블로그에서 사용하지 않는 `CLBackgroundActivitySession` 예시를 제거하고, Live Activity 정보 분리·표시 우선순위·갱신 및 종료 정책을 정리했다.
- 코스 판정 글에 위치 정확도 60m·수신 시각 15초·polyline 반경 150m·이동 현실성 45m/s와 80m 허용치·완료 거리 40%/5km 상한의 의미를 코드와 함께 정리했다. 순서·방향 완주를 증명하지 않는 한계와 GPS 측정 완료·서버 인증 완료의 경계도 명시했다.
- Live Activity 기술 블로그의 중복 예시와 인용문 서식을 정리하고, `approachProgress`의 내부 갱신 지표 역할, 위치 수신 중 15초 갱신 기준, 종료 후 30분 UI 유지 정책을 명확히 했다. 충족된 작성 체크리스트는 완료 처리하고 사진 출처 항목은 미완료로 유지했다.
- Live Activity 책임 분리, 앱 종료 직전 best-effort 정리, 위치·Live Activity 설정, 포트폴리오 백로그를 책임별 커밋으로 분리했다.
- 기술 블로그 작성 범위를 Core Location·Live Activity 종합 글, Live Activity 종료 실험 글, 실제 오류 중심 Swift 6 Migration 글의 세 편으로 확정했다. GPS 판정은 첫 글에 포함하고 GPS Replay·세션 복구는 독립 글 목록에서 제외했다.
- `PracticeLiveActivityService`는 ActivityKit 생명주기만 조정하고, 세션 매핑과 15초·3% 갱신 정책은 별도 타입으로 분리했다. 비동기 update/end는 단일 작업 체인으로 직렬화했고 iOS 16.2 `ActivityContent` API와 iOS 16.1 fallback을 함께 유지했다.
- Lock Screen·Dynamic Island 콘텐츠와 경로 진행 컴포넌트를 Widget 진입점에서 분리했다. 표시 결과는 유지하면서 phase 문자열 비교와 미사용 attributes·content state·asset을 정리했다.
- 개발용 Live Activity 세션 fixture를 Debug 영역으로 이동하고 갱신 정책 XCTest를 추가했다.
- `Docs/Portfolio/FEATURE_EXPLORATION_BACKLOG.md`에 코스 진입·완료 시 Live Activity와 함께 중요 상태를 알리는 로컬 알림 TODO를 추가하고, 권한 거부·중복 알림 방지 검증을 명시했다.
- 확정 로드맵과 분리된 `Docs/Portfolio/FEATURE_EXPLORATION_BACKLOG.md`를 추가해 TTS, CarPlay, watchOS·WatchConnectivity, WidgetKit, 광고·결제, 대규모 목록·이미지 캐시·미디어 탐색 항목과 구현 전 확인 기준을 기록했다.
- 기술 블로그 백로그에 Swift 6가 데이터 레이스를 컴파일 단계에서 진단하게 된 배경부터 격리·소유권·컴파일러 보장의 한계까지 연결하는 Migration 글의 제목과 대주제 목차를 추가했다.
- 기술 블로그 백로그에 GPS 오차를 걸러 polyline 진행률을 계산하는 글과 앱 재실행 시 주행 세션을 상태별로 복구하는 글의 작성 방향·검증 근거를 추가했다.
- 기술 블로그 소재와 검증 상태를 모아 관리하는 `Docs/Portfolio/TECH_BLOG_BACKLOG.md`를 추가했다. 현재 주행 추적 글, Live Activity 강제 종료 글, GPS Replay 글감을 근거·검증 상태와 함께 기록했다.
- `applicationWillTerminate` 에서 `Task.detached` 종료 작업을 최대 2초만 대기해 Rodi Live Activity를 즉시 종료하도록 연결했다. iOS 16.1은 기존 `end` API, 16.2 이상은 `ActivityContent` 오버로드로 분기했고, 프로세스 재실행 시 이전 sessionID의 Activity를 재개 선택 전에 정리하도록 보완했다.
- DrivePractice Service·Adapter 각 파일에 소유 책임과 비소유 책임을 설명하는 타입 주석을 추가했다.
- `DrivePracticeService`에서 인증 재시도 Task를 `DrivePracticeCertificationService`로, Core Location delegate·background activity session을 `DrivePracticeLocationAdapter`로 분리했다. 세션 정책·경로 판정·Live Activity 호출은 root service에 유지했고 인증 성공 revision, 취소·request ID 계약을 보존했다.
- `PracticeTracking` feature를 `DrivePractice`로 개명했다. 폴더·View·Reducer·Service·세션 모델과 Root/Home 의존성, 위치 권한 purpose key, 문서 경로를 함께 정리했고 기존 UserDefaults 키·analytics raw value는 호환성을 위해 유지했다.
- `PracticeReturnReducer`를 `PracticeTrackingReducer`에 흡수해 단일 사용 child State·Action·Delegate 중계를 제거했다. 앱 복귀·측정 연속·방문 기록·후기 권유 정책과 기존 debug Effect의 request revision·취소 계약은 root reducer에 유지했다.
- 홈 지도 재검색 버튼 누락을 수정했다. 추천 목록 로딩 중 사용자 viewport 이동은 버튼 표시 상태를 먼저 전달한 뒤 기존 목록 요청을 취소하며, 동일 순서를 검증하는 reducer XCTest를 추가했다. GPS·네트워크 주행 시나리오와 테스트 범위를 `Docs/Guides/GPS_REPLAY_TESTING.md`로 정리했다.
- 홈 지도 viewport 이동 뒤 재검색 버튼이 누락될 수 있는 P0 QA 이슈를 등록했다. 로딩 취소 경로의 표시 상태 미전파와 Kakao camera callback의 사용자 이동 오분류 위험을 원인으로 기록했으며, iOS 16.1~26 실기기·reducer 회귀 검증을 다음 작업으로 남겼다.
- `RodiKakaoMapView`의 configuration·lifecycle·render recovery·카메라·마커·경로·chrome·사용자 위치 extension 구현을 한 파일로 통합하고 파생 파일 11개를 삭제했다. 내부는 `MARK`로 구획했으며 Rodi Dev Debug build를 통과했다.
- `KakaoMapContainerView`의 nested `Coordinator`를 같은 파일로 합치고 분리된 `KakaoMapCoordinator.swift`를 삭제했다. Rodi Dev Debug build를 통과했다.
- 실행 환경이 실제 토큰 사용량을 제공하지 않을 때 의미 없는 placeholder가 반복되지 않도록, AGENTS의 토큰 사용 요약을 정확한 수치 제공 시에만 출력하도록 변경했다.
- 완료 보고의 `읽은 문서` 아래에 작업별 토큰 사용 요약을 최대 3줄로 남기도록 AGENTS 규칙을 추가했다. 실행 환경이 정확한 사용량을 제공하지 않으면 추정하지 않고 그 사실을 명시한다.
- Kakao SDK key 확인·초기화·중복 초기화 방지를 `KakaoConfiguration`으로 합치고 `KakaoMapService`를 삭제했다. `RodiApp`은 `KakaoConfiguration.initializeSDK()`만 호출하며, Rodi Dev Debug build를 통과했다.
- 부스 구현 심화 문서의 외부 길안내 설명을 Dynamic Link가 아닌 URL scheme·카카오내비 SDK URL 실행으로 바로잡고, GPS 판정은 정확도 60m·경로 corridor 150m·시간당 45m/s 상한을 통과한 위치 표본의 이동 거리를 누적하는 현재 정책으로 구체화했다.
- 개발 경험이 있는 부스 방문자를 위해 폴더 구조·MVI 용어를 제외한 구현 심화 질문 25개를 개발자 평가 문서 앞에 추가했다. 지도 SDK 연결, cluster, 요청 최신성, 위치·경로 판정, Live Activity, 후기 수정, 재시도·중복 방지 흐름을 조금 더 자세히 설명한다.
- 부스 방문자에게 바로 안내할 수 있도록 로그인·지도·검색·연습·Live Activity·후기·코스 등록·설정·오류를 다루는 일반 사용자용 FAQ 50문항을 별도 문서로 작성했다. 안전·도로·주차 가능 여부는 보장하지 않는다는 안내를 포함했다.
- 부스 현장 우선 질문은 MVI·Reducer 같은 내부 구조 용어를 빼고, 사용자 입력부터 지도·API·화면 반영까지의 구현 흐름으로 다시 작성했다.
- 개발자 부스에서 먼저 나올 가능성이 높은 cluster marker, 지도·검색 최신성, 코스 등록 핀, 외부 길안내, GPS·Live Activity, 후기 수정, 오류 상태 질문 15개를 문서 맨 앞에 빠른 답변으로 배치했다.
- 개발자 평가 문서에 클러스터링 marker, viewport·cursor 목록, filter, 장소 선택, 코스 등록 핀·경로, 길안내, 후기·차단, 재시도 UI 같은 서비스 구현 심화 질문·답변 30개를 추가했다.
- 개발자 평가용 내부 문서에 아키텍처, MVI, 동시성, Data 변환, 지도·위치, Live Activity, 보안, 배포, QA를 다루는 예상 질문·두괄식 답변 50개를 작성했다. 실기기 검증이 필요한 GPS·외부 앱·Live Activity 항목은 완료로 단정하지 않았다.
- Prod 1.4.3(2) 아카이브·App Store Connect 처리·내부 테스터 배포를 완료했다. 배포 전 Release simulator build를 통과했고, 현재 `main`은 origin에 푸시된 상태다.
- `/Users/mac/Desktop/rodiquiz`의 부스용 정적 퀴즈를 제공받은 경고표지·노면표시 원본에서 잘라낸 로컬 PNG 40개로 교체했다. 원본 설명 텍스트가 있는 하단 영역을 제외했고 워터마크·로고가 있는 자료는 사용하지 않았다. 서버·외부 요청 없이 `file://`로 동작한다.
- 부스 퀴즈는 완료 카드를 비활성화하지 않아 반복 응시할 수 있게 했고, 상단은 Rodi 앱 로고로 교체하고 표지 이미지를 확대했다. 오답 수정 모드는 제거했다.
- `/Users/mac/Downloads/퀴즈/완료`의 447~1000px 표지 6개를 파일명 기준 문항으로 교체했다. 기존 저해상도 크롭 자산은 더 이상 퀴즈에 참조하지 않는다.
- `/Users/mac/Downloads/퀴즈/진행중`의 표지 17개를 추가해 총 23개 이미지·46문항으로 늘렸다. 각 이미지는 2개의 다른 질문 문구로 출제하며, 홈 복귀 때 카드 번호는 1~46 순서를 유지하고 번호별 문제만 다시 무작위 배정한다. 문제 화면의 동작 버튼은 `홈으로 이동` 하나로 통일했다. Kixx 로고가 있던 정차금지지대 이미지는 로고 영역만 제거한 새 로컬 자산으로 교체했다.
- 퀴즈 이미지·CSS·JS를 모두 데이터 URL로 포함한 `Rodi_도로표지_퀴즈_단일파일.html`과 동일 내용의 ZIP을 만들었다. 전달받는 사람은 ZIP을 풀고 HTML 파일 하나만 열면 된다.
- 연습기록의 후기 가능 여부는 `PARKING` 태그 포함 여부가 아니라 서버 계약의 단일 `[PARKING]` 배열로 판별하도록 수정했다. 따라서 주차 유형을 포함한 코스는 `후기 작성`, 주차장만 `작성 불가`로 표시된다.
- Prod 연습 기록은 GPS 인증과 `register → recordVisit` 성공으로 통일했다. 코스만 인증 성공 뒤 후기 권유를 표시하며, 주차장은 후기 팝업 없이 연습기록 추가 안내·Home 갱신만 한다. Dev 코스는 외부 앱에서 5초 이상 체류 후 복귀할 때 테스트용 POST·후기 권유를 허용하며, 주차장의 시간 기반 self-report POST는 제거했다.
- 홈 추천목록 필터는 선택 카테고리의 연습유형만 열고, 같은 카테고리 재탭 시 해당 영역을 접도록 변경했다. 연습유형과 주차 필터는 카테고리 전환 뒤에도 누적 선택값으로 유지한다. 코스 등록도 단일 카테고리 표시를 유지하면서 이전 카테고리의 선택 연습유형을 보존한다.
- `Rodi Dev` Debug build와 iPhone 15 Pro simulator `RodiTests` 30건을 통과했다. 필터 카테고리 전환·주차 토글·코스 등록 카테고리 왕복의 수동 UI 확인이 남아 있다.
- 확장 Dynamic Island 상단은 각 영역의 폭 제약에 맞춰 상태명을 `이동 중`·`주행 중`·`완료`로 축약하고, 양쪽 4pt 여백과 12pt typography를 적용했다. 전체 상태명은 VoiceOver label로 유지한다.
- 확장 Dynamic Island가 잠금 화면용 카드·진행 바를 그대로 재사용해 하단이 잘리던 문제를 전용 축소 레이아웃으로 분리했다. 이동·주행·완료 상태는 짧은 텍스트와 얇은 진행 바로 표시하며, compact·minimal과 잠금 화면 카드 UI는 유지했다. Dynamic Island 지원 기기에서 세 상태의 시각 QA가 남아 있다.
- 둘러보기 단일 코스·주차장 마커 탭은 카메라·선택 상태를 바꾸기 전에 인증을 확인하도록 수정했다. 비로그인 상태에서는 로그인 요청만 전달하고 cluster 확대는 유지한다.
- 코스 등록 상세는 서버 정렬 첫 카테고리(현재 기초 주행)를 기본 선택하고, 카테고리를 단일 선택으로 전환했다. 전환 시 이전 연습유형을 정리하며 자동 기본값만으로 이탈 확인이 뜨지 않게 했다.
- 핀 수정은 선택 장소 확정 전 `완료`를 비활성화하고, 우회 Action도 취소·저장하지 않도록 보완했다. 공통 지도 route polyline 외곽선은 새 `RodiColor.primary800`(`#2600B1`)을 사용하도록 통일했다.
- Home Map·코스 등록 Details·핀 수정 회귀 XCTest 4건을 추가했다. iPhone 15 simulator의 전체 `RodiTests` 27건과 Dev Debug generic simulator build, `git diff --check`를 통과했다. iPhone 12 Pro에서 둘러보기 마커, 카테고리 전환, 핀 수정 완료 조건, 세 지도 route 외곽선의 수동 QA가 남아 있다.
- 코드리뷰 권장 묶음을 처리했다. My·ReviewFlow·차단목록 Snackbar 타이머에 취소 guard를 추가하고, 미사용 네트워크 UI·길안내 singleton·상세 chip 및 LicenseList 중복 참조를 제거했다. Home 검색과 코스 등록 지도 주소의 stale response 회귀 XCTest 3건을 추가했다.
- Central-MakeUs GitHub에 `1.2.0`부터 `1.4.2`까지 version tag를 반영하고, `v1.3.0`·`v1.4.0`·`v1.4.1`·`v1.4.2` 공개 Release를 버전 이력의 사용자용 패치노트로 생성했다. 기존 `v1.2.0` Release는 유지했다.
- `VERSION_HISTORY.md`에 1.4.2 사용자용 패치노트 3개 항목을 추가했다.
- Prod 강제 업데이트는 App Store 조회가 끝날 때까지 Root 진입을 보류하고, 최신 버전이 확인되면 기존 dialog만 표시하도록 보완했다. Dev에는 `-RODI_FORCE_REQUIRED_UPDATE` 실행 인자로 전체 차단 상태를 재현하는 실험 경로를 추가했다.
- Prod `1.4.2 (1)` archive와 TestFlight 업로드를 완료했다. App Store Connect의 build processing·배포 가능 상태 확인이 남아 있다.
- Prod 코스 연습은 GPS 인증·방문 기록 성공 시에만 후기 권유를 연다. Dev 코스는 현재 프로세스에서 시작한 세션이 외부 앱에 5초 이상 머문 뒤 복귀하면 테스트용 `register → recordVisit → 후기 권유`를 자동 수행한다.
- 추천 목록이 중간 높이의 빈 결과를 표시할 때만 indicator 아래에 레이아웃을 바꾸지 않는 48pt 투명 수직 drag 영역을 추가했다. 기존 제목·필터·빈 결과 콘텐츠의 터치 계약은 변경하지 않았다.
- Live Activity만 `release/1.4.1` 동작으로 복구했다. 코스 완료는 서버 저장 완료를 기다리지 않고 즉시 기존 완료 카드로 전환하며, 저장 중 상태·완료/진행 딥링크·세션별 Activity 정리·6개 프리뷰는 제거했다. 연습 기록 저장·세션 복구·로그아웃 정리 로직은 유지했다.
- 후기 작성·코스 상세 후기·저장 목록·차단 목록·등록 코스·내 후기·온보딩 프로필의 네트워크 오류 문구를 모두 `네트워크 연결을 확인해주세요.`로 통일했다. 기존 연습기록 적용분까지 활성 사용처를 정적 확인했다.
- 행정구역 선택 뒤 추천 목록의 성공 응답이 빈 배열이면, 중간 높이 시트에서도 기존 `추천할 수 있는 연습 코스를 찾지 못했어요.` 빈 결과를 가용 영역 중앙에 표시하도록 했다. 일반 지도 재검색은 기존 상단 배치를 유지한다.
- 저장목록의 코스·주차장 선택도 Home의 선택 마커·상세 시트와 함께 검색창 뒤로가기·장소명을 표시하도록 같은 선택 상태를 유지했다.
- 내 활동의 후기 본문이 비었거나 공백뿐이면 본문 텍스트와 테두리 컨테이너를 함께 생략했다.
- 코스 등록 지도 단계는 Root의 공통 네트워크 새로고침 스낵바를 그대로 받고, 단절이 3초 지속될 때만 공용 지도 대체 화면을 표시하도록 했다. 검색·상세 입력 단계에는 표시하지 않는다.
- 홈 검색의 최근 검색 header 시작 여백을 검색 필드 하단 여백과 합쳐 8pt가 되도록 조정하고, `전체삭제` 표기와 특별시·광역시 생략 표기를 지역 결과·최근 검색에 적용했다. 서버 원문과 최근 검색 저장값은 유지한다.
- 행정구역 선택의 지도 카메라 완료와 추천 목록 초기화가 엇갈려 목록 API가 생략될 수 있던 경합을 보완했다. 선택한 지역 중심을 시트에 먼저 보관해 이벤트 순서와 무관하게 목록 조회를 시작한다.
- 마이 연습기록·저장목록·내 활동(등록한 코스/작성한 후기)·차단 목록을 포함한 오류 재시도 UI를 공통 `RodiRetryButton`으로 통일했다. 버튼은 8pt 내부 여백, 6pt radius, 흰색 body2 텍스트와 primary 채움을 사용한다.
- 지역 선택 뒤 추천 목록은 성공한 `GET /api/v1/places`의 빈 `items` 배열일 때만 현재 빈 문구를 표시하며, 전용 서버 상태 코드·문구는 없음을 확인했다. 서울 viewport 표본 응답에는 항목이 존재했다.
- Dev 빌드에서는 현재 프로세스에서 시작한 코스 연습이 외부 앱에 10초 이상 머문 뒤 복귀하면, GPS 완주와 무관하게 연습 생성·방문 기록 POST를 자동 수행하도록 테스트 경로를 추가했다. 강제 종료 뒤의 15분 재개 선택 정책과 Release 동작은 유지한다.
- 앱 프로세스 재시작 뒤 Live Activity 캐시가 비어도 `rodi://live-activity?sessionID=...` 링크로 탭한 카드의 시스템 Activity만 찾아 즉시 종료하도록 정리했다. 탭은 앱 진입만 수행하며, 측정·방문 기록 상태는 바꾸지 않는다.
- `test/1.4.2-refactoring` 브랜치에서 연습 측정 저장 경계, 공통 제품 책임, 홈 지도·길안내, 마이 의존성, 동시성 격리, 화면 레이아웃, 후기 테스트를 책임 단위 커밋으로 재구성했다.
- 코드리뷰 권장 순서의 P0·P1·P2 정리를 마쳤다. 연습 측정 모델·저장 contract를 Domain/Data Local로 분리하고 schema v1 lazy migration, 손상 payload 정리, 로그아웃·탈퇴 시 측정 session·Live Activity 정리를 추가했다.
- Core에 섞여 있던 제품 책임을 이동했다: rabbit 이미지와 nested Config·Analytics catalog는 Presentation Shared, LegalDocument는 Presentation Shared Model, KakaoConfiguration은 App Configuration으로 옮겼다. Firebase 전송 adapter와 URL·키 이름은 유지했다.
- 미사용 launch loading View와 LicenseList 중복 project reference를 제거하고, 코드리뷰·Presentation·미해결·API 문서 및 테스트 target 안내를 현재 기준으로 갱신했다.
- `RodiLevelProfileImageConfig`를 별도 전역 타입으로 유지하지 않고 `RodiLevelProfileImage.Config`로 통합했다. 기존 레벨 기반 initializer는 유지하고, config 기반 initializer를 추가했다.
- 코스·주차장 상세의 중복 길안내 action/effect를 `Home/BottomSheet/RouteGuidance/RouteGuidanceReducer`로 통합했다. 공통 child는 앱 선택·Live Activity 권한·외부 앱 실행·취소·request ID를 소유하고, 각 상세 reducer는 장소별 측정 저장과 결과 delegate만 처리한다.
- `RodiTests`의 Repository·Writing/SkipReason service stub을 현재 protocol에 맞췄고, 주의사항은 선택 입력이라는 후기 작성 정책에 맞게 기대값을 고쳤다. `PracticeMeasurementStore` migration·손상 payload·정리 테스트를 추가했고, iPhone 17 Pro simulator의 `xcodebuild test`에서 8건이 통과했다.
- 전체 프로젝트 정적 코드리뷰 결과를 `Docs/CodeReview/PROJECT_CODE_REVIEW_2026-08-20.md`에 기록했다. 앱 타깃 빌드는 통과했지만 RodiTests는 최근 Repository·Service protocol 변경을 반영하지 못해 컴파일에 실패했다. 연습 측정 저장 경계(P0), Core 제품 책임 3건(P1), dead code·Xcode package 중복·문서 기준선·측정 전 성능 항목(P2)을 우선순위와 검증 조건으로 정리했다.
- 1.4.2 개인정보처리방침과 위치기반서비스 이용약관에서 Keychain·UserDefaults·토큰·기기 저장소 등 개발 구현 표현을 제거하고, 이용자 관점의 로그인·연습 진행 정보 처리 문구로 정리했다.
- 완료 Live Activity의 `기록하러 가기` 딥링크 소비 시 코스는 연습기록 이동, 주차장은 홈 이동 후 해당 완료 Activity만 즉시 종료하도록 처리했다.
- `HomeMapReducer`를 추가해 Home root의 지도 카메라·권한·위치 갱신·마커·Kakao 결과 처리와 request revision·heading stream·progressive rendering Effect를 분리했다. Home root는 Map/Search/BottomSheet typed Delegate 중재만 담당한다.
- Login tooltip과 Onboarding 분석 dialog의 직접 `UIScreen.main` 의존을 제거했고, 코스·주차장 길안내 부모의 쓰이지 않는 child-state proxy를 정리했다. Presentation 활성 백로그는 완료 표로 이동했다.
- Presentation 잔여 P1·P2 5건을 모두 완료 처리했다. `HomeMapReducer` 분리, 길안내 child proxy 제거, Login·Onboarding 화면 크기 의존 제거, 장문 파일 재감사를 마쳤고 Dev Debug build·RodiTests 8건·`git diff --check`를 다시 통과했다. 실기기 지도·외부 길안내·SE/대형 기기 UI 검증만 남았다.
- 코드리뷰 P2-CR-4에 2,001개 좌표 경로 매칭 XCTest metric과 1,000개 marker progressive snapshot 계약 테스트를 추가했다. marker batch의 사전 prefix 배열 생성을 제거해 peak allocation을 낮췄고, Simulator metric은 20회 매칭 평균 0.006초·추가 physical memory 평균 약 262KB였다. 연결된 iPhone은 secure connection 오류로 실기기 계측을 시작하지 못해 재측정이 남았다.

- AGENTS와 분야별 활성 문서의 중복 규칙과 오래된 기준을 정리했다.
- 2026-08-19~20 리팩터링·코드리뷰 기록과 이전 HandOff 상세 내역을 Archive로 이동해, 현재 작업 상태와 과거 근거를 분리했다.
- 문서 탐색의 확장·종료 조건, skill 선택 경계와 결과 품질 측정 기준을 추가했다.
- API 전체 인벤토리를 Archive에 보존하고, endpoint 검증 기록은 API 가이드에 통합했다.
- 결함·검증·구조 개선·API 계약·기능 후보·글쓰기 작업을 `Docs/TODO.md`의 단일 상태 원본으로 통합했다.
- Architecture에 Layer 계약과 한국어 코드 주석 기준을 합치고, API 연결 기록은 API 가이드에 흡수했다.
- 발표·회고 자료 3개를 Archive로 옮기고 GPS 테스트 가이드를 `Docs/Tests/`로 이동해 활성 Docs를 7개로 유지했다.
- AGENTS의 문서 안내를 단일 표로 합치고 Archive·Handoff·TODO 탐색 조건과 UI 가이드의 불일치 판단 기준을 맞췄다.

## Next

- [TODO](../Docs/TODO.md)의 대상 ID를 기준으로 다음 작업을 선택하고, 완료된 항목은 검증 뒤 삭제한다.

## Verification

- `bash Scripts/validate_documentation.sh`에서 Markdown 106개 링크와 폐기 문서 참조 검사를 통과했다.
- `git diff --check`를 통과했다.
- 이동 문서의 본문·TODO ID 보존과 UI·API·Reducer·배포·GPS 요청 5종의 문서 선택 규칙을 정적으로 확인했다. 실제 AI 작업의 토큰 사용량·결과 품질은 측정하지 않았다.
- 이번 작업은 문서·문서 검사 스크립트·Handoff만 변경하므로 Xcode build와 실기기 QA는 실행하지 않았다.

## Archive

- 이전 상세 기록: [윤달 HandOff 2026-09-05](archive/윤달_HandOff_2026-09-05.md)
