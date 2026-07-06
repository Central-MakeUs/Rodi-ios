# RODI Release, App Store, And Legal Notes

This document combines release commands, App Store submission notes, privacy/legal draft guidance, and location-service safeguards.

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
- Apple/Kakao login entry points are implemented. Do not claim server-side account storage until backend account creation/persistence is implemented.
- Do not list Firebase, Analytics, IDFA, user content, ads, community, reviews, points, or driving record storage unless implemented.
- App description must say RODI is map-based course discovery with external navigation handoff, not a full standalone navigation app.
- Country availability can be Korea-focused if desired, because Kakao map usage is Korea-centered.
- Review notes should explain Kakao map/location limitations for foreign testers and simulator locations.

Suggested Privacy Label:
- Precise Location: collected
- Purpose: App Functionality
- Linked to user: No
- Tracking: No

## Current Data Handling

Current MVP implementation:
- uses location when the user grants while-in-use permission
- shows nearby courses, single places, and parking
- supports 3km, 5km, 10km radius filters
- moves map to current location
- passes coordinates to KakaoMap/KakaoNavi or Kakao Mobility APIs for external route handling
- stores onboarding completion locally through Realm
- provides Apple/Kakao login entry points, but does not yet persist RODI server account data
- does not store user location history on a RODI server
- does not implement review, community, point, ad, or driving-record features

## Legal Draft Content To Keep Aligned

Privacy policy should say:
- location is used only when permission is granted
- location supports nearby map display, radius filter, current-location button, and external navigation handoff
- RODI server does not store location history
- Kakao services may receive coordinates during map, route, or handoff flows
- onboarding completion is stored locally and removed when the app is deleted
- support email, privacy contact, and effective date must be finalized before release
- third-party authentication providers, if kept for release, should be reflected in privacy/legal wording and App Store Connect metadata

Location terms should say:
- location permission can be denied
- whole-course browsing can remain available without location
- current-location features may be limited without permission
- RODI does not guarantee road conditions, safety, accident prevention, or parking availability
- external Kakao services are governed by Kakao's own policies

Service terms should say:
- RODI provides reference information for driving practice
- the driver remains responsible for traffic laws and real road conditions
- external navigation results are not guaranteed by RODI
- unimplemented features should not be described as current functionality

Support page should include:
- app name
- support email
- supported inquiry types
- expected response time
- links to service terms, privacy policy, and location terms
- safety disclaimer

## Location Business Safeguards

This section is for location-based service business filing preparation, not App Store submission itself.

Current implementation-aligned statements:
- location permission is requested only while using the app
- RODI server does not store location history
- Kakao API calls use HTTPS
- API keys are excluded from version control through local secrets
- Release builds should fail when required Kakao keys are missing
- Release logs must not expose full keys or precise coordinates

Do not claim:
- Firebase stores location logs
- user location history is automatically retained for 6 months
- member information, reviews, community, points, driving records, IDFA, or analytics are collected

Before filing, confirm:
- location information manager
- privacy manager
- support email
- support URL
- location collection/use/provision record retention obligation
- whether the business filing is required and completed

## Release Safety

- Keep `Config/Secrets.local.xcconfig` out of git.
- Keep `.p8` files out of git.
- Do not expose full API keys in build logs.
- Archive/TestFlight verification does not replace App Store legal and metadata review.
