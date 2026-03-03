# LoggerApp

Privacy-first iOS nutrition tracker built with SwiftUI, SwiftData, async/await, and a local-first architecture.

## Highlights

- Dual food lookup flow: Open Food Facts for packaged foods and barcodes, curated seed JSON for generic foods
- AI-assisted photo logging and natural-language parsing with strict JSON decoding
- Daily dashboard with calorie and macro progress, meal breakdown, and behavioral nudges
- Weight trend tracking with 7-day moving average and optional HealthKit sync
- GLP-1 reminder and dose logging with local notifications
- Keychain-backed API key storage and local export/delete controls

## File Tree

```text
LoggerApp/
├── LoggerApp.xcodeproj
├── LoggerApp/
│   ├── App/
│   ├── Core/
│   ├── Food/
│   ├── Logging/
│   ├── Weight/
│   ├── Medication/
│   ├── AI/
│   ├── Settings/
│   └── Notifications/
├── LoggerAppTests/
│   ├── Fixtures/
│   ├── AIDecodingTests.swift
│   ├── FoodRepositoryRoutingTests.swift
│   ├── MacroCalculatorTests.swift
│   ├── MockFoodItems.swift
│   └── NutritionMathTests.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Seeds/
└── project.yml
```

## Setup

1. Install `xcodegen` if it is not already available: `brew install xcodegen`
2. Generate the project: `xcodegen generate`
3. Open `LoggerApp.xcodeproj` in Xcode 26 or newer
4. Run the `LoggerApp` scheme on an iOS 17+ simulator or device
5. Add your Anthropic API key in the app Settings before using AI photo or text logging

## Notes

- Open Food Facts search is intentionally user-triggered instead of search-as-you-type to stay within OFF usage guidance.
- As of March 3, 2026, Anthropic’s official model list includes `claude-opus-4-6`, and the app client is configured to use that identifier.
- HealthKit remains behind a user-facing toggle. App capabilities still need to be enabled in the Apple Developer portal for device builds that use HealthKit.

## Verification

- Build: `xcodebuild -scheme LoggerApp -project LoggerApp.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16e' build`
- Tests: `xcodebuild test -scheme LoggerApp -project LoggerApp.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16e'`

## Remaining TODO Checklist

- Add production App Store icon assets and marketing copy
- Add camera/photo snapshot UI tests and notification scheduling integration tests
- Add Open Food Facts request throttling persistence if you expect heavy packaged-food search usage
- Enable HealthKit capability and notification categories in the signed app target before release
- Add localization strings and accessibility audit pass before App Store submission
