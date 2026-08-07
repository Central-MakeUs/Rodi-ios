# RODI Agent Guide

RODI is a map-based driving-practice course discovery app for beginner drivers and long-inactive license holders.

## Non-Negotiables

- Never claim or imply guaranteed safety, accident prevention, road conditions, or parking availability.
- Prefer “practice reference”, “practice suitability”, “difficulty”, “recommended for practice”, and “external navigation handoff”.
- Never commit Kakao keys, OAuth/access/refresh tokens, App Store Connect private keys, `.p8` files, local xcconfig secrets, or private Firebase files.
- Never expose complete secrets, tokens, or precise user coordinates in responses or committed logs. Release logs must contain none of them.
- Do not modify `Rodi/Data/Local` unless the task explicitly includes local persistence.
- Minimum deployment target is iOS 16.1. Gate newer APIs with `#available` and provide an iOS 16.1 fallback.

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

If documentation and live code differ, use the live implementation and repair the document in the same task or report the drift. If Swagger and a DTO differ, verify endpoint, version, and environment before changing the DTO.

## Minimal Context Router

Read `AGENTS.md`, then normally only one task document:

- Foldering, MVI, ownership, refactoring: `Docs/ARCHITECTURE.md`
- Figma, SwiftUI, UIKit, assets, layout: `Docs/UI_FIGMA.md`
- Swagger, DTO, API, repository: `Docs/API_SWAGGER.md`
- Dev/Prod, TestFlight, privacy, analytics: `Docs/RELEASE.md`

Load a second document only for a genuinely mixed task. Start with `rg` for the target symbol and adjacent implementation instead of reading a whole layer.

`Docs/Archive` is historical evidence, not default context. Read a specific archived file only when the user asks about a past incident, migration, or decision.

## Work Loop

1. Restate the requested outcome and constraints.
2. Inspect Git state, target symbols, adjacent code, and the primary source.
3. Make the smallest coherent plan; call out assumptions only when they change scope.
4. Implement in small, reviewable edits while preserving unrelated user changes.
5. Review the diff for ownership, availability, privacy, and stale documentation.
6. Run verification proportional to the change and report what was and was not verified.

Do not create handoff files, nested `AGENTS.md`, temporary TODO documents, or new skills for one-off work. Add durable documentation only when it reduces repeated decisions across tasks.

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

## Skills

- Use `.agents/skills/rodi-swiftui` only for SwiftUI implementation or review.
- Project docs and adjacent code override skill defaults.
- Do not treat `.opencode/legacy-skills` as active guidance.
- Figma work uses the connected design-to-code tooling plus `Docs/UI_FIGMA.md`; do not infer implementation from generated React/Tailwind literally.

## Verification

After Swift code or project-structure changes, run the Dev Debug build:

```sh
xcodebuild -project /Users/mac/Documents/iOS_projects/SwiftUI/Rodi/Rodi.xcodeproj -scheme "Rodi Dev" -configuration Debug -destination "generic/platform=iOS Simulator" build
```

For release, signing, configuration, or environment changes, also verify the `Rodi` Release path described in `Docs/RELEASE.md`. Documentation-only and project-skill-only changes do not require an Xcode build.

The project currently has no test target. Do not claim tests passed. Report static checks, builds, and manual scenarios separately.

Before handoff, run `git diff --check`, confirm no secret/local files entered the diff, and ensure changed active docs still point to real paths and symbols.
