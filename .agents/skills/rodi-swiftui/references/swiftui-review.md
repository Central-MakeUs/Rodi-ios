# SwiftUI Review

## Review in This Order

1. Confirm that the change matches the requested UI and existing Rodi component behavior.
2. Confirm iOS 16.1 availability and the current ObservableObject/MVICore integration.
3. Check layout adaptability and stable identity.
4. Check rendering cost and lifecycle work.
5. Check accessibility and every visible state.

Follow `Docs/ARCHITECTURE.md` for MVI ownership and foldering; do not create competing conventions here.

## Preserve Identity

- Give dynamic elements stable, domain-derived identifiers.
- Avoid indices and `\.self` for mutable or duplicate collections.
- Avoid `AnyView` and unnecessary conditional branches that replace the underlying view type.
- Keep state with the logical element it represents when ordering or filtering can change.
- Verify insert, delete, reorder, refresh, and pagination behavior when relevant.

## Keep Rendering Cheap

- Keep initializers and `body` free of I/O, sorting, filtering, parsing, formatter creation, and other repeated work.
- Derive or cache transformed data at the existing state boundary, with explicit invalidation when caching.
- Use `LazyVStack` or `LazyHStack` for large scrolling collections.
- Avoid starting duplicate effects from repeated appearance callbacks; preserve the reducer's lifecycle and cancellation contract.
- Prefer concrete views, `Group`, generics, and existing components over type erasure.
- Extract UI only when it clarifies ownership or reuse; follow Rodi's same-file extension and feature conventions from active Docs.

## Check Accessibility

- Give interactive controls meaningful VoiceOver labels and use `Button` instead of a plain tap gesture when tap location or count is unnecessary.
- Hide decorative images from accessibility; label informative images by purpose.
- Keep effective tap targets at least 44 by 44 points.
- Support Dynamic Type and long localized text without clipping essential content.
- Do not communicate meaning by color alone; verify contrast against actual Rodi colors.
- Respect Reduce Motion and avoid making essential state changes animation-only.
- Preserve focus order and group complex content when it improves comprehension.

## Check Product States

- Inspect loading, empty, error, and success rendering rather than only the populated happy path.
- Check disabled, selected, pressed, and in-progress interaction states where applicable.
- Verify compact and large devices, safe areas, keyboard overlap, and repeated navigation.

## Report Findings

- Report only reproducible defects or material risks.
- Order findings by user impact.
- Include file and line, consequence, violated project constraint, and the smallest iOS 16.1-compatible correction.
- Separate confirmed issues from optional polish.
