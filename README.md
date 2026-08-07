<h1 align="center">Rodi</h1>

<table align="center">
<tr>
<td align="center"><img width="1320" height="2868" alt="1" src="https://github.com/user-attachments/assets/7616cb2d-ad89-4c68-bcc7-85d0b9e46e1d" /></td>
<td align="center"><img width="1320" height="2868" alt="2" src="https://github.com/user-attachments/assets/1548f15a-c8d0-477a-95f3-55d7c23bcd05" /></td>
<td align="center"><img width="1320" height="2868" alt="3" src="https://github.com/user-attachments/assets/261e462f-e702-459b-b801-268a3a5eda88" /></td>
<td align="center"><img width="1320" height="2868" alt="4" src="https://github.com/user-attachments/assets/5ca29030-5678-49ab-9aee-f60564932828" /></td>
<td align="center"><img width="1320" height="2868" alt="5" src="https://github.com/user-attachments/assets/0fb73daf-0839-4677-a1b3-e9f15843e886" /></td>
</tr>
</table>

<p align="center">
<b>Rodi</b>는 <b>초보 운전자와 장롱면허 운전자</b>를 위한<br/>
맞춤형 운전 연습 장소 및 코스 탐색 서비스입니다.
</p>

<p align="center">
현 위치를 기준으로 주변 운전 연습 코스, 공영 주차장, 경유지가 포함된 경로를 확인하고<br/>
카카오맵·카카오내비와 연동해 바로 길안내를 시작할 수 있습니다.
</p>

<p align="center">
<a href="https://apps.apple.com/kr/app/id6785479816">
<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
alt="Download on the App Store"
height="48" />
</a>
</p>

<br/>

# 서비스 소개

Rodi는 운전 연습이 막막한 초보 운전자에게 주변 연습 코스와 주차 연습 장소를 지도 기반으로 제공합니다.

- 카카오·Apple 소셜 로그인 및 비회원 둘러보기
- 운전 경험·선호 정보 기반 온보딩과 운전 레벨, 추천 연습 유형 안내
- 현재 위치 또는 지도 화면 범위 기반 코스·주차장 탐색과 재검색
- 줌 단계별 마커 클러스터링, 코스·주차장 상세 정보 및 경로 미리보기
- 출발지, 경유지, 도착지를 포함한 코스 경로와 카카오맵·카카오내비 길안내 연동
- 회원 북마크, 저장 목록, 운전 목표를 관리하는 마이페이지

> Rodi는 운전 연습에 참고할 수 있는 코스 정보를 제공하는 서비스이며, 실제 도로 상황과 안전을 보장하지 않습니다. 사용자는 항상 교통 법규와 현장 상황을 우선해야 합니다.
> 

<br/>

# 폴더 구조

```bash
|-- Rodi
    |-- App                         # 앱 진입점, RootView, AppRouter, 의존성 조합
    |
    |-- Core                        # 공통 인프라 및 기반 코드
    |   |-- Analytics               # Firebase Analytics 이벤트 경계
    |   |-- Architecture            # AppDependencies, MVICore
    |   |-- Components              # 공통 UI 컴포넌트
    |   |-- Coordinator             # typed NavigationStack 경로 관리
    |   |-- Extension               # Swift / SwiftUI 공통 Extension
    |   |-- Network                 # 네트워크 매니저, 인터셉터, Keychain 토큰 저장
    |   |-- Service                 # Logger, Snackbar 등 공통 서비스
    |
    |-- Data                        # 외부/로컬 데이터 구현 레이어
    |   |-- Local                   # UserDefaults 기반 온보딩 초안, 최근 로그인 제공자 저장
    |   |-- Remote                  # Auth, Member, Place 서버 API 연동 구현
    |
    |-- Domain                      # 앱 핵심 도메인 계약 및 모델
    |   |-- Auth                    # 인증 도메인
    |   |-- Member                  # 회원 프로필 및 온보딩 도메인
    |   |-- Place                   # 코스, 주차장, 북마크 도메인
    |
    |-- Presentation                # 화면 및 사용자 인터랙션 레이어
    |   |-- Home                    # 지도, BottomSheet, Search
    |   |-- Login                   # 소셜 로그인, 둘러보기, 탈퇴 계정 복구
    |   |-- MainTab                 # 탭 상태와 Feature 간 이동 intent
    |   |-- My                      # MyReducer, Coordinator, 운전 목표, 저장 목록
    |   |-- Onboarding              # Coordinator 기반 Terms, Profile, Permission
    |
    |-- Resources                   # 앱 리소스
        |-- Assets.xcassets         # 이미지, 아이콘 에셋
        |-- Fonts                   # Pretendard 폰트
        |-- PrivacyInfo.xcprivacy   # 앱 개인정보 매니페스트
```

# 아키텍처

Rodi는 SwiftUI를 기반으로 하되, 지도 SDK가 UIKit 중심이라는 점을 분리해 다룹니다.

- `AppRouter`는 온보딩과 메인 탭의 전역 전환, 로그인 필요 화면을 관리합니다.
- `MainTabReducer`는 탭 선택과 Feature 간 intent만 소유하며 Home/My 화면은 탭 전환 뒤에도 유지됩니다.
- Home은 Map, BottomSheet, Search 영역을 합성하며, 지도 SDK adapter와 화면 상태·API Effect의 책임을 분리합니다.
- Onboarding은 `NavigationStack` 기반 RouterView 위에서 Login, Terms, Profile, Permission Feature가 각자 입력·검증·비동기 처리를 담당합니다.
- `AppDependencies`에서 Repository를 한 번 만들고 명시적으로 주입해, View나 Reducer가 전역 container를 직접 참조하지 않습니다.
- Home/My 탭은 숨겨져도 유지하며, 지도 좌표 요청은 취소와 revision으로 늦은 응답이 최신 상태를 덮지 못하게 합니다.
- access/refresh token은 하나의 Keychain 세션 레코드로 원자적으로 저장하고 기존 분리 저장값은 첫 읽기 때 이전합니다.

# 개발 환경

- `Rodi Dev` / Debug: `com.dororong.rodi.dev`, 내부 개발·디버깅·TestFlight 검증
- `Rodi` / Release: `com.dororong.rodi`, 운영 배포·App Store 제출
- 환경별 Firebase, Clarity, 앱 아이콘, 표시명, 버전 값은 `Config/Dev.xcconfig`, `Config/Prod.xcconfig`에서 관리합니다.
- 실제 키와 Firebase plist는 local config 및 Git ignore로 관리합니다.
