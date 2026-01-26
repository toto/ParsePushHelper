# Repository Guidelines

## Project Structure & Module Organization
Project sources live inside `ParsePushHelper.xcodeproj` with Swift packages split into `Sources/App` (UI for iOS/iPadOS/Catalyst), `Sources/Core` (networking, push scheduling, data models), and `Sources/SharedUI` (reusable components). Assets stay in `Resources/Assets.xcassets`, localized strings under `Resources/<lang>.lproj`, and configuration templates like `PushService.plist` live in `Config/`. Unit and snapshot tests live in `Tests/AppTests` and `Tests/SnapshotTests`, while UITests reside in `Tests/UITests`. Automation scripts belong in `Tools/`.

## Build, Test, and Development Commands
Install dependencies with Swift Package Manager using Xcode. Build locally with `xcodebuild -scheme ParsePushHelper -destination 'platform=iOS Simulator,name=iPhone 15' build`. Run tests via `xcodebuild test -scheme ParsePush -destination 'platform=iOS Simulator,name=iPhone 15'`; append `-destination 'platform=macOS,variant=Mac Catalyst'` for Catalyst coverage. Build dependencies are set up in `Mintfile`   Use `fastlane` for automation. 

## Coding Style & Naming Conventions
All code uses Swift 6 with async/await. Prefer structured concurrency (`Task`, `TaskGroup`) and actors for shared state. Keep 4-space indentation, use `MARK:` comments to segment files, and group extensions by protocol conformance. Name view controllers and SwiftUI views as `<Feature>ViewController`/`<Feature>View` and test files mirroring targets (e.g., `PushSchedulerTests.swift`). Avoid force unwraps (if really needed add comment explaining why); rely on `guard` for early exits and document public APIs with Swift-DocC comments. 

Build in an MVVM architecture. Prefrer SwiftUI over UIKit unless explitly asked. Avoid dependencies for networking or model code if possible. Only use `@Observable` instead of `ObservableObject` for SwiftUI and UIKit. For UIKit use the iOS 26 `updateProperties` and `setNeedsUpdateProperties()` method in `UIViewController` and `UIView`.

## Testing Guidelines
Unit tests rely on XCTest with async expectations; use `@MainActor` when touching UI. Snapshot tests use `iOS18-iPhone15` reference images stored under `Tests/SnapshotTests/__Snapshots__`. UITests must include accessibility identifiers matching `AccessibilityID.swift` constants. Maintain ≥90% coverage on `Sources/Core`, and ensure every async workflow has at least one integration test hitting the mock push service found in `Tests/Fixtures`. Regenerate mocks via `make generate-mocks` when protocols change.

## Commit & Pull Request Guidelines
Follow Conventional Commits (e.g., `feat: add push intent handoff`, `fix: await token refresh on launch`). Each PR must outline the platform touched (iOS, iPadOS, Catalyst), screenshots or screen recordings for UI changes, and any migration steps (schema bumps, entitlement changes). Confirm `xcodebuild test` against iOS and Catalyst before requesting review, link the tracking issue, and call out background task or notification entitlement updates when applicable.

## Platform & Security Notes
Store secrets such as push service API keys in `Config/Secrets.sample.plist` and never commit filled files. Verify background refresh and push capabilities remain enabled after editing targets. When adding new async workflows, audit for `@MainActor` violations to avoid UI hangs.
