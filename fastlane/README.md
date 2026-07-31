fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios version

```sh
[bundle exec] fastlane ios version
```

Show the current app version and build number

### ios build_dev

```sh
[bundle exec] fastlane ios build_dev
```

Build Rodi Dev for the iOS Simulator

### ios archive_prod

```sh
[bundle exec] fastlane ios archive_prod
```

Create a production App Store archive locally

### ios dev_beta

```sh
[bundle exec] fastlane ios dev_beta
```

Push a new development beta build to the Rodi Dev TestFlight app. The lane uses
the Dev app's current TestFlight version and build train, without changing the
production version or build number.

### ios prod_beta

```sh
[bundle exec] fastlane ios prod_beta
```

Push a new production beta build to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
