# RODI Release, App Store, And Legal Notes

This document combines release commands, App Store submission notes, and legal-release safeguards.

The legal source of truth is `Docs/Legal`:

- `TERMS_OF_SERVICE.md`
- `PRIVACY_POLICY.md`
- `LOCATION_BASED_SERVICES_TERMS.md`

Do not use this operational document as the text to publish. Update the three legal documents first, then reflect the approved text in public pages and App Store metadata.

## Fastlane

Rodi uses fastlane only on the local Mac. GitHub Actions is not configured.

Setup:

```sh
bundle install
cp Config/Secrets.example.xcconfig Config/Secrets.local.xcconfig
```

Local secrets belong in `Config/Secrets.local.xcconfig`:

```xcconfig
KAKAO_NATIVE_APP_KEY =
KAKAO_REST_API_KEY =
APP_STORE_CONNECT_KEY_ID =
APP_STORE_CONNECT_ISSUER_ID =
APP_STORE_CONNECT_API_KEY_PATH =
APP_STORE_APP_ID =
```

Keep `.p8` files local. `Config/AuthKey_*.p8` and `fastlane/AuthKey_*.p8` are ignored by git.

Commands:

```sh
bundle exec fastlane build
bundle exec fastlane archive
bundle exec fastlane beta
bundle exec fastlane version
```

Use `BUILD_NUMBER` when needed:

```sh
BUILD_NUMBER=2 bundle exec fastlane beta
```

## App Store Connect Checklist

- Support URL must be a public HTTPS page.
- Privacy Label must match actual implementation.
- Current code uses precise location for app functionality.
- Apple/Kakao login entry points, server-backed member data, onboarding profile data, bookmarks, and account withdrawal/recovery are implemented. Privacy Label and legal text must reflect the deployed backend behavior.
- Do not list Firebase, Analytics, IDFA, ads, community, reviews, points, or driving record storage unless implemented in the release build.
- App description must say RODI is map-based course discovery with external navigation handoff, not a full standalone navigation app.
- Country availability can be Korea-focused if desired, because Kakao map usage is Korea-centered.
- Review notes should explain Kakao map/location limitations for foreign testers and simulator locations.

Privacy Label must be confirmed against the actual backend and third-party SDK behavior. Do not copy the former MVP-only suggestion without verifying whether location, member profile, onboarding, and bookmark data are linked to a user.

## Current Data Handling

Current implementation:
- supports guest browsing and Kakao/Apple social login
- stores authentication tokens in Keychain, incomplete onboarding drafts in Realm, and recent login provider/onboarding display state in UserDefaults
- sends current location or viewport coordinates to the Rodi server for place discovery and can pass route coordinates to Kakao services
- provides member onboarding profiles, calculated driving level, bookmarks, saved places, my page, driving-goal updates, account withdrawal, and account recovery
- does not store location history as a separate movement history
- does not implement review, community, points, ads, or driving-record features

## Legal Publication Checklist

- Finalize the effective date in all three `Docs/Legal` documents.
- Resolve their marked TODO items with server operations and legal review before public publication.
- Keep terms, privacy policy, location terms, App Store Privacy Label, and the deployed backend behavior aligned.
- Public pages should include app name, support email, links to all three documents, and the driving-practice safety disclaimer.

## Location Business Safeguards

This section is for location-based service business filing preparation, not App Store submission itself.

Current implementation-aligned statements:
- location permission is requested only while using the app
- RODI server receives place-query coordinates but does not claim to store a separate location history
- Kakao API calls use HTTPS
- API keys are excluded from version control through local secrets
- Release logs must not expose full keys or precise coordinates

Do not claim unimplemented Firebase, analytics, IDFA, reviews, community, points, or driving-record collection.

Before filing, confirm:
- location information manager
- privacy manager
- support email
- support URL
- location collection/use/provision record retention obligation
- Kakao REST key platform restrictions and a future server-proxy migration for the client-bundled key
- whether the business filing is required and completed

## Release Safety

- Keep `Config/Secrets.local.xcconfig` out of git.
- Keep `.p8` files out of git.
- Do not expose full API keys in build logs.
- Archive/TestFlight verification does not replace App Store legal and metadata review.
