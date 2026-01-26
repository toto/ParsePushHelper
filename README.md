# Parse Push Helper

Parse Push Helper is a macOS + iOS app for composing and sending push notifications through a Parse Server backend.

## Features (current)
- Manage multiple Parse Server configurations
- Secure API key storage in Keychain
- Compose flow stub with message, targeting, and delivery options

## Project Structure
- `Sources/App`: App UI (SwiftUI)
- `Sources/Core`: Models and data storage
- `Sources/SharedUI`: Reusable UI components
- `Resources`: Assets and localization
- `Tests`: Unit, snapshot, and UI tests

## Getting Started
1. Open `ParsePush.xcodeproj` in Xcode.
2. Select the `ParsePush` scheme.
3. Run on an iOS Simulator or Mac Catalyst.

## Tooling & Automation
- Dependencies: Swift Package Manager (resolved by Xcode).
- Automation: `fastlane` (see `fastlane/`).
- Build: `xcodebuild -scheme ParsePush -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Test (iOS): `xcodebuild test -scheme ParsePush -destination 'platform=iOS Simulator,name=iPhone 15'`
- Test (Catalyst): add `-destination 'platform=macOS,variant=Mac Catalyst'`

## Notes
- API keys are stored in the Keychain and are not persisted in user defaults.
- The compose flow is a placeholder and will be expanded with real sending logic.
