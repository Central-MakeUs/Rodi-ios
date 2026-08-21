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

## Protected Core Foundations

- MUST NOT modify, move, rename, or delete files under `Rodi/Core/Architecture/MVICore`, `Rodi/Core/Coordinator`, or `Rodi/Core/Network`.
- If a task requires a change in a protected Core foundation, MUST stop before writing and ask the user for explicit approval. The request MUST identify the exact file, reason, and expected impact.
- MAY read, search, and include protected Core foundations in build verification. MUST NOT create a copy or workaround to bypass this approval rule.

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

문서·skill·작업 절차의 전체 안내는 `Docs/Guides/WORKING_GUIDE.md`를 참고한다. 단, 실제 구현 작업에서는 아래의 주제별 문서를 먼저 선택하고, 안내 문서는 필요할 때만 추가로 읽는다.

- 전체 architecture, 의존성 방향, MVI: `Docs/Architecture/ARCHITECTURE.md`
- App 리팩터링: `Docs/Architecture/Layers/APP.md`
- Core 리팩터링: `Docs/Architecture/Layers/CORE.md`
- Data 리팩터링: `Docs/Architecture/Layers/DATA.md`
- Domain 리팩터링: `Docs/Architecture/Layers/DOMAIN.md`
- Presentation 리팩터링: `Docs/Architecture/Layers/PRESENTATION.md`
- Resources 리팩터링: `Docs/Architecture/Layers/RESOURCES.md`
- `@MainActor`, `Task`, actor, cancellation, `async` 흐름 리팩터링: `Docs/Architecture/ARCHITECTURE.md`와 대상 Layer 문서
- Figma, SwiftUI, UIKit, assets, layout: `Docs/Guides/UI_FIGMA.md`
- Swagger, DTO, API, repository: `Docs/API/API_SWAGGER.md` 및 `Docs/API/API_CONNECTION_STATUS.md`
- Dev/Prod, TestFlight, privacy, analytics: `Docs/Release/RELEASE.md`

SHOULD load a second document only for a genuinely mixed task. MUST start with `rg` for the target symbol and adjacent implementation instead of reading a whole layer.

`Docs/Archive` is historical evidence, not default context. MUST read a specific archived file only when the user asks about a past incident, migration, or decision.

## Work Loop

1. MUST restate the requested outcome and constraints.
2. MUST inspect Git state, target symbols, adjacent code, and the primary source.
3. SHOULD make the smallest coherent plan; MUST call out assumptions only when they change scope.
4. MUST implement in small, reviewable edits while preserving unrelated user changes.
5. MUST review the diff for ownership, availability, privacy, and stale documentation.
6. MUST run verification proportional to the change and report what was and was not verified.

MUST NOT create ad-hoc handoff files, nested `AGENTS.md`, temporary TODO documents, or new skills for one-off work. The durable root `Handoff/` workflow defined below is the only exception. SHOULD add durable documentation only when it reduces repeated decisions across tasks.

## Handoff Rules

- `Handoff/` is the root for durable personal work-continuity records. This explicit root-level workflow is an exception to the normal rule that new project documentation belongs under `Docs/`.
- The personal file MUST be named `Handoff/{GitOwnerName}_HandOff.md`. If it does not exist, MUST create it and register it in `Handoff/INDEX.md`.
- The file owner MUST update only their own HandOff. Other contributors' HandOff files MAY be read but MUST NOT be edited.
- After completing code, documentation, refactoring, or verification work, MUST record the current state, completed work, next work, and verification result concisely in the owner's HandOff.
- MUST move obsolete detailed records to `Handoff/archive/` so the personal HandOff keeps only the latest work, next work, and verification summary.
- `Handoff/INDEX.md` MUST remain a short directory and status view; it MUST NOT replace QA issues, release history, or refactoring backlogs in `Docs/`.

## Durable Rule Capture

- MUST treat an explicitly emphasized user instruction as a candidate durable rule when it is likely to apply to future tasks.
- MUST treat a constraint, correction, or workflow preference discovered repeatedly across tasks as a candidate durable rule even when the user does not explicitly request documentation.
- MUST update the narrowest existing authority document that owns the rule. Use `AGENTS.md` for cross-cutting execution rules and the relevant task document for layer, API, UI, release, or feature-specific rules.
- MUST NOT create a new document for a one-off preference or a rule already covered by an existing document.
- When a durable rule is added or changed, MUST reread `AGENTS.md` before continuing the current command or implementation work so the updated rule applies immediately.

## Markdown Documentation Style

- MUST create new project documentation under `Docs/`, except for the durable personal records explicitly allowed by `Handoff Rules`. Existing documentation MUST remain at its established path unless the task explicitly includes a documented relocation.
- MUST write new Markdown documents in Korean unless the user explicitly requests another language.
- MUST express normative rules with `MUST`, `MUST NOT`, or `SHOULD`.
- MUST NOT use those keywords for non-normative background, examples, or historical facts.
- SHOULD structure durable guidance with clear headings for purpose, scope, and verification when applicable.

## Final Report Requirements

- Every final response after completing work MUST include a short `읽은 문서` line.
- The line MUST list every Markdown document actually read during that turn, including `AGENTS.md`; it MUST NOT list documents that were not read.
- Every readable Markdown document in the line MUST use a clickable repository-relative Markdown link. For example: `읽은 문서: [AGENTS.md](AGENTS.md), [ARCHITECTURE.md](Docs/Architecture/ARCHITECTURE.md)`.
- If a task required no additional project document, the line MUST say `읽은 문서: [AGENTS.md](AGENTS.md)`.
- A skill instruction or non-Markdown resource MAY remain a compact plain-text path when it cannot be linked reliably in the final response.
- The final response SHOULD keep this list compact and separate it from build, static-check, and manual-verification results.

## Long-running Work Progress

- MUST report the current work-batch progress and the overall backlog completion rate whenever a long-running implementation, refactoring, QA, or migration batch reaches a verified milestone.
- MUST base the overall completion rate on the active items recorded in the task's authoritative backlog document, and MUST distinguish completed, in-progress, deferred, and blocked items.
- SHOULD keep progress reporting concise and include the next planned batch so the user can assess scope and remaining risk.

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

For a non-trivial Presentation feature, keep the feature root as the entry point and organize implementation by responsibility. Put only real responsibilities in `Component`, `SubView`, `SubPage`, `Section`, `Model`, `Service`, or `Adapter`; do not leave a flow root View to accumulate its pages, reusable UI, models, and I/O. Read `Docs/Architecture/ARCHITECTURE.md` before making foldering decisions.

## Skills

- Use `.agents/skills/rodi-swiftui` only for SwiftUI implementation or review.
- Project docs and adjacent code override skill defaults.
- Do not treat `.opencode/legacy-skills` as active guidance.
- MUST use `.agents/skills/swiftui-expert-skill` only for SwiftUI performance, state ownership, accessibility, navigation, or Instruments review. `rodi-swiftui` and project Docs override its iOS 17+ and generic architecture guidance.
- MUST use `.agents/skills/swift-concurrency-performance` when a task changes or diagnoses the lifetime, cancellation, reentrancy, or responsiveness contract of `@MainActor` or async work. General syntax-only changes MUST NOT trigger it.
- MUST use `.agents/skills/ios-launch-performance` only for launch-time regressions.
- MUST use `.agents/skills/ios-performance-profiling` only when choosing or interpreting Instruments, memory, CPU, hang, hitch, or allocation measurement.
- MUST use `.agents/skills/ios-perceived-performance` only for loading feedback, progressive rendering, or interaction-latency work.
- MUST use `.agents/skills/swiftui-performance`, `.agents/skills/swift-concurrency-performance`, or `.agents/skills/swift-runtime-performance` only when the request is explicitly about the matching performance concern.
- MUST NOT use performance skills as a reason to optimize without measurement or to override RODI's iOS 16.1, MVICore, Feature foldering, or Figma rules.
- MUST NOT automatically update project-local external skills; an upstream diff and iOS 16.1 compatibility review are required before adoption.

### Figma 작업

Figma URL 또는 `node-id`가 포함된 구현 요청에서는 다음을 따른다.

1. MUST use the available `figma` and `figma-design-to-code` skills.
2. MUST call `get_design_context` for the target node before writing code, then call `get_screenshot` to confirm the visual state.
3. MUST treat generated example code as structural reference only. Live project architecture, design system, navigation, accessibility, and asset conventions take precedence.
4. MUST add Figma-provided assets through the project asset-catalog policy; temporary asset URLs MUST NOT remain in source code.
5. SHOULD also use `figma-swiftui` for SwiftUI or iOS implementation work.
6. If the required Figma tooling is unavailable, MUST report that limitation before implementation and use the supplied screenshot only as a fallback.

Figma work uses `Docs/Guides/UI_FIGMA.md`; generated React/Tailwind MUST NOT be copied literally.

## Touch Targets

- For a selectable row, tile, card, or container, make the entire visible rectangle tappable with `Button` and `contentShape(Rectangle())`; empty space must trigger the same primary action unless it contains a separate control.

## Git Staging And Push

- MUST when the user requests split staging and push, separate changes into coherent commits by feature or responsibility.
- MUST choose the Conventional Commit type from the actual change: `feat`, `fix`, `hotfix`, `refactor`, or `chore`.
- MUST use `<type>: <한글 명사형>` for each resulting commit message, ending the Korean summary with a noun such as `구현`, `분리`, or `정리`.
- MUST use `refactor` for behavior-preserving structural changes and `chore` for documentation, tooling, or repository maintenance.
- MUST NOT mix unrelated feature, refactoring, and documentation changes in the same commit.
- MUST inspect the staged diff for each commit and verify its scope before committing or pushing.

## Fastlane Deployment

- MUST use `bundle exec fastlane ios dev_beta` to upload a Dev TestFlight build.
- MUST use `bundle exec fastlane ios prod_beta` to upload a Prod TestFlight build.
- MUST verify the selected scheme, local secrets, and version/build number before either upload command.

## Verification

After Swift code or project-structure changes, run the Dev Debug build:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme "Rodi Dev" -configuration Debug -destination "generic/platform=iOS Simulator" build
```

For release, signing, configuration, or environment changes, also verify the `Rodi` Release path described in `Docs/Release/RELEASE.md`. Documentation-only and project-skill-only changes do not require an Xcode build.

The project has the `RodiTests` test target. MUST report the exact executed test command and pass/fail result; builds, automated tests, static checks, and manual scenarios MUST remain separate in the final report.

Before handoff, run `git diff --check`, confirm no secret/local files entered the diff, and ensure changed active docs still point to real paths and symbols.
