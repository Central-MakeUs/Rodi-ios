# RODI Agent Guide

RODI is a map-based driving-practice course discovery app for beginner drivers and long-inactive license holders.

## Non-Negotiables

- MUST NOT claim or imply guaranteed safety, accident prevention, road conditions, or parking availability.
- SHOULD prefer “practice reference”, “practice suitability”, “difficulty”, “recommended for practice”, and “external navigation handoff”.
- MUST NOT commit Kakao keys, OAuth/access/refresh tokens, App Store Connect private keys, `.p8` files, local xcconfig secrets, or private Firebase files.
- MUST NOT expose complete secrets, tokens, or precise user coordinates in responses or committed logs. Release logs MUST contain none of them.
- MUST NOT modify `Rodi/Data/Local` unless the task explicitly includes local persistence.
- MUST support iOS 16.1. Newer APIs MUST be gated with `#available` and have an iOS 16.1 fallback.
- MUST explain a proposed Live Activity UI change and obtain the user's explicit approval before implementing it.

## Source of Truth

Apply context in this order:

1. The user’s current request
2. Security, privacy, and product-safety constraints
3. The task’s primary source
   - architecture behavior: live code
   - backend contract: Swagger for the named environment/version
   - UI contract: the referenced Figma node and screenshot
4. One relevant active document
5. A project skill only when its trigger matches
6. General platform knowledge

If documentation and live code differ, MUST use the live implementation and repair the document in the same task or report the drift. If Swagger and a DTO differ, MUST verify endpoint, version, and environment before changing the DTO.

## Minimal Context Router

MUST read `AGENTS.md`, then normally only one task document:

문서·skill·작업 절차의 전체 안내는 `Docs/WORKING_GUIDE.md`를 참고한다. 단, 실제 구현 작업에서는 아래의 주제별 문서를 먼저 선택하고, 안내 문서는 필요할 때만 추가로 읽는다.

- Foldering, MVI, ownership, refactoring: `Docs/ARCHITECTURE.md`
- Figma, SwiftUI, UIKit, assets, layout: `Docs/UI_FIGMA.md`
- Swagger, DTO, API, repository: `Docs/API_SWAGGER.md` 및 `Docs/API_CONNECTION_STATUS.md`
- Dev/Prod, TestFlight, privacy, analytics: `Docs/RELEASE.md`
- 2차 업데이트의 연습 측정·재진입·후기 팝업: `Docs/SECOND_UPDATE.md`

SHOULD load a second document only for a genuinely mixed task. MUST start with `rg` for the target symbol and adjacent implementation instead of reading a whole layer.

`Docs/Archive` is historical evidence, not default context. MUST read a specific archived file only when the user asks about a past incident, migration, or decision.

## Work Loop

1. MUST restate the requested outcome and constraints.
2. MUST inspect Git state, target symbols, adjacent code, and the primary source.
3. SHOULD make the smallest coherent plan; MUST call out assumptions only when they change scope.
4. MUST implement in small, reviewable edits while preserving unrelated user changes.
5. MUST review the diff for ownership, availability, privacy, and stale documentation.
6. MUST run verification proportional to the change and report what was and was not verified.

MUST NOT create handoff files, nested `AGENTS.md`, temporary TODO documents, or new skills for one-off work. SHOULD add durable documentation only when it reduces repeated decisions across tasks.

## Final Report Requirements

- Every final response after completing work MUST include a short `읽은 문서` line.
- The line MUST list every Markdown document actually read during that turn, including `AGENTS.md`; it MUST NOT list documents that were not read.
- If a task required no additional project document, the line MUST say `읽은 문서: AGENTS.md`.
- The final response SHOULD keep this list compact and separate it from build, static-check, and manual-verification results.

## Project Shape

```text
Rodi/
  App/
  Core/
  Data/
  Domain/
  Presentation/
  Resources/
```

Use the live filesystem as the source of truth. Xcode uses filesystem-synchronized groups, but verify file moves and build membership after structural changes.

For a non-trivial Presentation feature, keep the feature root as the entry point and organize implementation by responsibility. Put only real responsibilities in `Component`, `SubView`, `SubPage`, `Section`, `Model`, `Service`, or `Adapter`; do not leave a flow root View to accumulate its pages, reusable UI, models, and I/O. Read `Docs/ARCHITECTURE.md` before making foldering decisions.

## Skills

- Use `.agents/skills/rodi-swiftui` only for SwiftUI implementation or review.
- Project docs and adjacent code override skill defaults.
- Do not treat `.opencode/legacy-skills` as active guidance.

### Figma 작업

Figma URL 또는 `node-id`가 포함된 구현 요청에서는 다음을 따른다.

1. MUST use the available `figma` and `figma-design-to-code` skills.
2. MUST call `get_design_context` for the target node before writing code, then call `get_screenshot` to confirm the visual state.
3. MUST treat generated example code as structural reference only. Live project architecture, design system, navigation, accessibility, and asset conventions take precedence.
4. MUST add Figma-provided assets through the project asset-catalog policy; temporary asset URLs MUST NOT remain in source code.
5. SHOULD also use `figma-swiftui` for SwiftUI or iOS implementation work.
6. If the required Figma tooling is unavailable, MUST report that limitation before implementation and use the supplied screenshot only as a fallback.

Figma work uses `Docs/UI_FIGMA.md`; generated React/Tailwind MUST NOT be copied literally.

## Touch Targets

- For a selectable row, tile, card, or container, make the entire visible rectangle tappable with `Button` and `contentShape(Rectangle())`; empty space must trigger the same primary action unless it contains a separate control.

## Verification

After Swift code or project-structure changes, run the Dev Debug build:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme "Rodi Dev" -configuration Debug -destination "generic/platform=iOS Simulator" build
```

For release, signing, configuration, or environment changes, also verify the `Rodi` Release path described in `Docs/RELEASE.md`. Documentation-only and project-skill-only changes do not require an Xcode build.

The project currently has no test target. Do not claim tests passed. Report static checks, builds, and manual scenarios separately.

Before handoff, run `git diff --check`, confirm no secret/local files entered the diff, and ensure changed active docs still point to real paths and symbols.
