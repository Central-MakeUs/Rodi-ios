# GPS Replay·주행 시나리오 테스트 가이드

## 목적

이 문서는 RODI의 위치 기반 연습 측정을 재현 가능하게 검증하기 위한 GPS Replay와 네트워크 시나리오의 기준을 정의한다. 실제 GPS 궤적을 저장하거나 사용자 위치를 수집하는 기능의 설계 문서가 아니다.

현재 연습 측정은 위치 정확도, 표본 시각, 코스 경로와의 거리, 이동 거리의 타당성을 함께 확인한다. 테스트는 이 정책이 위치·네트워크·앱 수명주기 변화에서 의도하지 않은 완료나 인증 상태 전환을 만들지 않는지 검증한다.

## 범위와 원칙

- MUST fixture에 실제 이용자 좌표, 이동 기록, 장소 이름, 식별자를 넣지 않는다.
- MUST 합성 경로 또는 테스트 전용 상대 좌표를 사용한다.
- MUST 위치 재생과 네트워크 상태 재생을 별도 입력으로 유지하고, 시나리오 타임라인에서만 조합한다.
- MUST production `CLLocationManager`와 실제 repository를 테스트 편의상 바꾸지 않는다. 테스트용 위치·네트워크 입력은 Adapter 또는 Service 경계에서 주입한다.
- MUST GPS 인증·방문 기록·후기 권유의 서버 저장 여부는 위치 판정과 분리해 검증한다.
- SHOULD 순수 위치 판정은 단위 테스트로, Core Location·백그라운드·외부 앱 왕복은 실기기 수동 QA로 검증한다.

## 현재 판정 기준

`DrivePracticeService`의 현재 정책은 다음과 같다.

| 구분 | 현재 기준 | 테스트 관점 |
| --- | --- | --- |
| 위치 표본 수용 | 수평 정확도 60m 이하, 현재 시각과 15초 이내 | 부정확·오래된 표본은 진행률과 완료를 바꾸지 않는다. |
| 코스 진입 | route polyline에서 150m 이내 | 코스 밖 표본은 주행 단계로 진입시키지 않는다. |
| 이동 거리 | 표본 간 최대 60초만 시간으로 반영 | 장시간 위치 공백이 시간을 과도하게 누적하지 않는다. |
| 물리적 타당성 | 초당 45m와 허용 오차를 넘는 이동은 거리 누적 제외 | 순간 이동 좌표가 완주로 이어지지 않는다. |
| 완료 기준 | 코스 전체 거리의 40%, 최대 5km | 정상 주행 표본만 완료 조건에 기여한다. |
| 프로세스 복원 | 코스 진입 전에는 제한적 재개, 주행 중 재시작은 중단 | GPS 연속성이 끊긴 주행을 임의로 이어 붙이지 않는다. |

## Replay 입력 모델

GPS Replay Engine은 Apple의 단일 공식 프레임워크 이름이 아니라, 아래 입력을 시간 순서로 재생하는 테스트 구성이다.

```text
Scenario Timeline
  ├─ Location sample: 상대 좌표, timestamp, horizontal accuracy
  ├─ Location event: 표본 누락, 중복, 순서 역전, 위치 서비스 오류
  ├─ Network event: online, offline, timeout, recovery
  └─ App event: foreground, background, process restart, external navigation return
       ↓
Test Location Adapter / Test Repository
       ↓
DrivePracticeService · DrivePracticeReducer
       ↓
Session 상태 · 방문 기록 요청 · Live Activity 상태 검증
```

Xcode Simulator의 GPX 재생은 정상 이동 확인에 사용한다. 정확도 저하, 오래된 timestamp, 중복·순서 역전 표본, 네트워크 단절, 프로세스 재시작은 앱 내부의 테스트 입력으로 재현한다.

## 우선 시나리오

| ID | 상황 | 타임라인 핵심 | 기대 결과 | 우선 검증 |
| --- | --- | --- | --- | --- |
| GPS-01 | 정상 코스 진입·주행 | 접근 → corridor 진입 → 정상 간격 표본 | `headingToCourse`에서 `drivingCourse`로 전환되고, 유효 거리만 누적 | 단위 테스트 |
| GPS-02 | 낮은 정확도 | 주행 중 정확도 60m 초과 표본 삽입 | 해당 표본은 진행률·완료·주행 거리에 영향 없음 | 단위 테스트 |
| GPS-03 | 위치 공백·오래된 표본 | 60초 초과 공백, 현재보다 15초 이상 오래된 표본 | 오래된 표본은 무시되고, 재개 후 시간 누적은 상한을 넘지 않음 | 단위 테스트 |
| GPS-04 | 순간 이동·역방향·중복 | 비현실적인 큰 이동, 이전 timestamp, 같은 표본 반복 | 비정상 이동은 거리 누적에 기여하지 않고 세션은 안전하게 유지 | 단위 테스트 |
| GPS-05 | 코스 이탈 후 복귀 | corridor 밖 표본 → 정상 표본 | 이탈 구간은 거리 누적하지 않고, 복귀 뒤 정상 판정 재개 | 단위 테스트 |
| GPS-06 | 주행 10% 지점 네트워크 단절 | 유효 주행 중 offline → 완료 뒤 repository 실패 → recovery | GPS 진행 판단은 유지하고, 인증/방문 기록은 pending 상태로 남아 중복 요청 없이 재시도 | reducer·repository stub |
| GPS-07 | 외부 길안내·백그라운드 복귀 | 외부 앱 전환 → background → foreground | 위치 권한·세션·Live Activity가 현재 정책대로 유지되며, 늦은 callback이 종료 세션을 되살리지 않음 | 실기기 QA |
| GPS-08 | 프로세스 재시작 | 접근 단계 재시작 / 주행 단계 재시작 | 접근 단계는 grace period 정책을 적용하고, 주행 단계는 `interrupted`로 종료 | 단위 테스트·실기기 QA |
| GPS-09 | 권한·정확도 변경 | 권한 거부, reduced accuracy, full accuracy 복귀 | 측정을 시작하지 않거나 현재 안내 정책을 유지하며, 권한 복귀 뒤 새 시작 흐름으로 확인 | 실기기 QA |
| GPS-10 | 주차장 도착 | 접근 → corridor 진입 | 주차장 도착은 즉시 완료 처리하되 코스 후기 정책과 섞이지 않음 | 단위 테스트 |

## 구현 순서

구현·검증 대기 상태는 [TODO](../TODO.md)의 `TEST-001`에서 관리한다. 이 문서는 입력 모델과 반복 가능한 시나리오의 원본만 유지한다.

## 완료 기준

- MUST GPS-01~06의 핵심 상태 전이를 자동 테스트로 검증한다.
- MUST 시나리오마다 입력 표본, 예상 상태 전이, 예상 repository 호출 횟수를 명시한다.
- MUST 네트워크 단절·취소·재시도 후 이전 요청 결과가 최신 상태를 덮어쓰지 않는지 검증한다.
- MUST 위치 저장소와 로그에 원본 GPS 궤적을 남기지 않는다.
- SHOULD GPS-07~10의 실기기 결과를 [TODO](../TODO.md)의 관련 `QA` 항목에 기록한다.

기술 블로그 작성 상태는 [TODO](../TODO.md)의 `WRITE-001`에서 관리한다.
