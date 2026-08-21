# Core 레이어 규칙

## 목적

`Core`는 여러 top-level feature가 공유하는 기술 기반과 UI 기반을 제공한다. 제품 Feature의 정책을 보관하는 공용 폴더가 아니다.

## 보호 영역

- `Rodi/Core/Architecture/MVICore`, `Rodi/Core/Coordinator`, `Rodi/Core/Network`의 파일은 MUST NOT 수정, 이동, 이름 변경 또는 삭제한다.
- 기능 구현에 보호 영역 변경이 필요하면 MUST 작업을 멈추고, 대상 파일·필요 이유·예상 영향을 사용자에게 제시해 명시적 허락을 받아야 한다.
- 보호 영역의 읽기, 검색, 빌드 검증은 허용한다. 이 규칙을 우회하기 위한 복제본 또는 대체 구현을 MUST NOT 만든다.

## MUST

- MUST `MVICore`, 공통 Network 기반, Logger, typed Coordinator, 공통 design-system Component를 Core에 둔다.
- MUST 위치·네트워크 상태처럼 여러 Feature가 관찰하는 시스템 상태의 monitor를 Core에 둔다.
- MUST Core API가 제품 Feature의 구체 타입 대신 일반적 typed value 또는 protocol을 사용하게 한다.
- MUST 공통 Component가 실제로 두 개 이상의 top-level feature에서 재사용되는지 확인한 뒤 Core로 이동한다.
- SHOULD UIKit bridge나 SDK helper가 앱 전역에서 재사용될 때만 Core 후보로 검토한다.

## MUST NOT

- MUST NOT 코스, 후기, 회원, 연습기록의 제품 규칙이나 Feature route를 Core에 둔다.
- MUST NOT Core가 Presentation·Data의 구체 Feature 타입을 import하게 한다.
- MUST NOT 위치 권한 관찰과 코스 상세의 위치 사용 정책을 같은 Core 타입에 결합한다.
- MUST NOT 단일 Feature에서만 쓰이는 Component·Service를 재사용 가능성만으로 Core에 올린다.
- MUST NOT 앱 시작 환경, 강제 업데이트, SDK 초기화처럼 App lifecycle에 결합된 설정을 Core에 둔다.

## 검토 기준

- 새 Core 타입에는 최소 두 Feature의 실제 사용처 또는 전역 기술 경계라는 근거가 있어야 한다.
- Core 변경 뒤에는 영향 Feature와 iOS 16.1 availability fallback을 확인한다.
