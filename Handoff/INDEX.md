# HandOff 색인

## 목적

이 폴더는 개인 작업의 완료 내용, 현재 상태, 다음 작업, 검증 근거를 짧게 이어가기 위한 durable 기록이다. 미래 작업 상태는 `Docs/TODO.md`, 릴리스 이력은 기존 `Docs/` 문서를 원본으로 유지한다.

## 현재 작업자

| 작업자 | HandOff |
| --- | --- |
| 윤달 | [윤달 HandOff](윤달_HandOff.md) |

## 운영 규칙

- 작업자는 자신의 HandOff만 수정한다.
- 다른 작업자의 HandOff는 읽을 수 있지만 수정하지 않는다.
- 후속 작업자가 이어받아야 할 상태가 바뀐 경우 Current, Recent Work, Next, Validation을 간결하게 갱신한다.
- 상세 기록이 최신 상태 파악을 방해하면 `archive/`로 이동한다.
- 작업 재개 요청에서는 관련 개인 HandOff를 확인한다. archive는 과거 근거가 필요한 요청에서만 읽는다.
- `INDEX.md`에는 현재 상태를 복제하지 않고 작업자와 HandOff 위치만 기록한다.
