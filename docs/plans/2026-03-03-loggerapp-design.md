# LoggerApp Design Document

**Date:** 2026-03-03
**Project:** AI Nutrition + Macro + GLP-1 Tracker (Cronometer-Style iOS App)
**Status:** Approved

---

## Summary

A production-ready, privacy-first iOS application for accurate macro/calorie tracking, AI-powered food logging, barcode scanning, weight tracking, and GLP-1 medication reminders. Built with SwiftUI, SwiftData, Swift Concurrency, and Anthropic claude-opus-4-6 for AI features.

---

## Key Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Architecture | Feature folders, single Xcode target | Clean MVVM, simpler setup, production-grade |
| Persistence | SwiftData | iOS 17+ native, @Model macros, Swift Concurrency integration |
| AI Model | claude-opus-4-6 | Best accuracy for photo analysis and NLP food parsing |
| API Key Storage | User-entered, stored in Keychain | Privacy-first, no backend needed |
| Apple Health | HealthKit behind feature flag | Optional sync, off by default |
| Food Database | Dual: OFF (barcodes) + Generic JSON seed | Accurate sourcing by food type |

---

## Architecture

**Pattern:** MVVM + Repository Pattern + Dependency Injection
**Persistence:** SwiftData
**Networking:** URLSession async/await
**AI:** Anthropic Messages API (claude-opus-4-6)

### Module Structure

```
LoggerApp/
├── App/           — Entry point, DI assembly, navigation
├── Core/          — Shared models, protocols, utilities, Keychain
├── Food/          — FoodRepository, OFFClient, search, barcode scanner
├── Logging/       — LogRepository, daily log, meal entries
├── Weight/        — WeightRepository, trends, HealthKit bridge
├── Medication/    — GLP-1 tracker, injection log, scheduling
├── AI/            — AnthropicClient, photo + NLP, strict JSON decode
├── Settings/      — API key, macro goals, notification preferences
└── Notifications/ — NotificationManager, all reminder schedulers
```

---

## File Tree

```
LoggerApp/
├── LoggerApp.xcodeproj
├── LoggerApp/
│   ├── App/
│   │   ├── LoggerAppApp.swift
│   │   ├── RootView.swift
│   │   ├── AppContainer.swift
│   │   └── NavigationRouter.swift
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── FoodItem.swift
│   │   │   ├── FoodLog.swift
│   │   │   ├── LoggedFood.swift
│   │   │   ├── WeightEntry.swift
│   │   │   ├── MedicationDose.swift
│   │   │   ├── MedicationSchedule.swift
│   │   │   └── UserProfile.swift
│   │   ├── Extensions/
│   │   │   ├── Color+Brand.swift
│   │   │   └── Date+Helpers.swift
│   │   ├── Utilities/
│   │   │   ├── KeychainService.swift
│   │   │   ├── NutritionMath.swift
│   │   │   └── UnitConverter.swift
│   │   └── Protocols/
│   │       ├── FoodRepositoryProtocol.swift
│   │       ├── LogRepositoryProtocol.swift
│   │       ├── WeightRepositoryProtocol.swift
│   │       └── MedicationRepositoryProtocol.swift
│   ├── Food/
│   │   ├── Repositories/
│   │   │   ├── FoodRepository.swift
│   │   │   └── GenericFoodDatabase.swift
│   │   ├── Services/
│   │   │   ├── OFFClient.swift
│   │   │   └── OFFResponseParser.swift
│   │   ├── ViewModels/
│   │   │   ├── FoodSearchViewModel.swift
│   │   │   └── FoodDetailViewModel.swift
│   │   └── Views/
│   │       ├── FoodSearchView.swift
│   │       ├── FoodDetailView.swift
│   │       ├── BarcodeScannerView.swift
│   │       └── CustomFoodEditorView.swift
│   ├── Logging/
│   │   ├── Repositories/
│   │   │   └── LogRepository.swift
│   │   ├── ViewModels/
│   │   │   ├── DailyLogViewModel.swift
│   │   │   └── MealEntryViewModel.swift
│   │   └── Views/
│   │       ├── HomeView.swift
│   │       ├── MacroRingView.swift
│   │       ├── MealSectionView.swift
│   │       └── LogEntryConfirmView.swift
│   ├── Weight/
│   │   ├── Repositories/
│   │   │   └── WeightRepository.swift
│   │   ├── Services/
│   │   │   └── HealthKitService.swift
│   │   ├── ViewModels/
│   │   │   └── WeightViewModel.swift
│   │   └── Views/
│   │       ├── WeightEntryView.swift
│   │       └── WeightTrendView.swift
│   ├── Medication/
│   │   ├── Repositories/
│   │   │   └── MedicationRepository.swift
│   │   ├── ViewModels/
│   │   │   └── MedicationViewModel.swift
│   │   └── Views/
│   │       ├── GLP1TrackerView.swift
│   │       ├── InjectionLogView.swift
│   │       └── MedicationSetupView.swift
│   ├── AI/
│   │   ├── Models/
│   │   │   ├── AIFoodResponse.swift
│   │   │   └── AIFoodCandidate.swift
│   │   ├── Services/
│   │   │   └── AnthropicClient.swift
│   │   ├── ViewModels/
│   │   │   ├── PhotoLogViewModel.swift
│   │   │   └── NLPLogViewModel.swift
│   │   └── Views/
│   │       ├── PhotoCaptureView.swift
│   │       ├── PhotoReviewView.swift
│   │       └── NLPLogView.swift
│   ├── Settings/
│   │   ├── ViewModels/
│   │   │   └── SettingsViewModel.swift
│   │   └── Views/
│   │       ├── SettingsView.swift
│   │       ├── MacroGoalsView.swift
│   │       ├── APIKeyView.swift
│   │       └── NotificationPrefsView.swift
│   └── Notifications/
│       ├── NotificationManager.swift
│       └── NotificationScheduler.swift
├── LoggerAppTests/
│   ├── NutritionMathTests.swift
│   ├── MacroCalculatorTests.swift
│   ├── AIDecodingTests.swift
│   ├── FoodRepositoryRoutingTests.swift
│   └── Fixtures/
│       ├── MockFoodItems.swift
│       └── MockAIResponses.swift
└── Resources/
    └── Seeds/
        └── generic_foods.json
```

---

## Data Models

### FoodItem (@Model)
- `id: UUID`
- `name: String`
- `brand: String?`
- `barcode: String?`
- `source: FoodSource` (.off | .generic | .custom)
- `kcalPer100g: Double?` (explicit from source)
- `proteinPer100g: Double?`
- `carbsPer100g: Double?`
- `fatPer100g: Double?`
- `fiberPer100g: Double?`
- `sugarPer100g: Double?`
- `sodiumPer100mg: Double?`
- `isKcalEstimated: Bool` (true when computed via 4/4/9)
- `defaultServingGrams: Double`

### FoodLog (@Model)
- `id: UUID`
- `date: Date` (day granularity, normalized to midnight)
- `entries: [LoggedFood]`

### LoggedFood (@Model)
- `id: UUID`
- `foodItem: FoodItem`
- `amountGrams: Double`
- `meal: MealSlot` (.breakfast | .lunch | .dinner | .snack)
- `loggedAt: Date`

Nutrients computed at query time: `NutritionMath.scale(nutrient:per100g:amountGrams:)`

### WeightEntry (@Model)
- `id: UUID`
- `date: Date`
- `value: Double`
- `unit: WeightUnit` (.kg | .lb)

### MedicationSchedule (@Model)
- `id: UUID`
- `medicationName: String`
- `doseString: String` (display only, no units enforced)
- `frequency: MedicationFrequency` (.weekly | .custom(days: Int))
- `injectionSites: [String]` (rotation list)
- `nextDueDate: Date`
- `refillReminderDaysAhead: Int`

### MedicationDose (@Model)
- `id: UUID`
- `schedule: MedicationSchedule`
- `administeredAt: Date`
- `site: String`
- `sideEffects: String?`

### UserProfile (@Model)
- `id: UUID` (singleton, always use `.shared` accessor)
- `weightKg: Double`
- `heightCm: Double`
- `ageYears: Int`
- `sex: BiologicalSex`
- `activityLevel: ActivityLevel`
- `goal: NutritionGoal` (.cut | .maintain | .bulk)
- `customCalorieTarget: Double?` (overrides computed TDEE)
- `customProteinTarget: Double?`
- `appleHealthEnabled: Bool` (feature flag, default false)
- `notificationPreferences: NotificationPreferences`

---

## Repository Routing

```
FoodRepository.search(query:barcode:)
├── barcode != nil        → OFFClient.fetchByBarcode(_:)
├── query matches generic → GenericFoodDatabase.search(_:)
├── user's custom foods   → SwiftData query
└── AI candidate "packaged" → OFFClient.searchByName(_:) → fallback to AI values
```

---

## AI Integration

**Endpoint:** Anthropic Messages API
**Model:** claude-opus-4-6
**API Key:** Read from Keychain at call time

### Request format (photo mode)
```json
{
  "model": "claude-opus-4-6",
  "max_tokens": 1024,
  "messages": [{
    "role": "user",
    "content": [
      { "type": "image", "source": { "type": "base64", "media_type": "image/jpeg", "data": "..." }},
      { "type": "text", "text": "Identify foods in this image. Return JSON only matching this schema: ..." }
    ]
  }]
}
```

### Response JSON Schema
```json
{
  "items": [{
    "name": "string",
    "category": "generic|packaged|recipe",
    "estimated_portion": { "amount": 0, "unit": "g|oz|cup|tbsp|piece|ml" },
    "confidence": 0.0,
    "notes": "string"
  }],
  "assumptions": ["string"],
  "needs_user_confirmation": true
}
```

**Rules:**
- Confidence < 0.75 → `needsUserConfirmation = true`
- Malformed JSON → `AIError.malformedResponse`, show error state, never crash
- User must confirm before any item is logged
- No medical advice, no micronutrient fabrication

---

## NutritionMath

Pure enum with static functions, zero dependencies:

```swift
NutritionMath.scale(nutrient:per100g:amountGrams:) → Double
NutritionMath.computedKcal(protein:carbs:fat:) → Double        // 4/4/9
NutritionMath.bmr(weight:height:age:sex:) → Double             // Mifflin-St Jeor
NutritionMath.tdee(bmr:activityLevel:) → Double
NutritionMath.macroTargets(tdee:goal:) → MacroTargets
```

Goal macro splits:
- `.cut`: −500 kcal deficit, 40% protein / 35% carbs / 25% fat
- `.maintain`: 30% protein / 40% carbs / 30% fat
- `.bulk`: +300 kcal surplus, 25% protein / 50% carbs / 25% fat

---

## Navigation

`RootView`: `TabView` with 5 tabs
1. Today (HomeView)
2. Search (FoodSearchView)
3. Trends (WeightTrendView + weekly summaries)
4. GLP-1 (GLP1TrackerView)
5. Settings (SettingsView)

Sheets: FoodDetail, PhotoReview, NLPLog, BarcodeScan, LogEntryConfirm

---

## Notifications

All via `UNUserNotificationCenter`. Permission requested on Settings open, not at launch.

| Notification | Trigger |
|---|---|
| Meal reminder | Daily at configured time |
| Protein target | When user logs but hasn't hit protein goal by 8pm |
| Weigh-in | Weekly or daily at configured time |
| GLP-1 (24h) | 24h before next dose due |
| GLP-1 (2h) | 2h before next dose due |
| Missed dose | 2h after due date if not logged |
| Refill | N days before estimated run-out |
| Hydration | Optional, user-configured interval |

All notification types have individual toggles in `NotificationPrefsView`.

---

## Error Handling

- OFF API failure → show cached result or "nutrition unavailable" state; never block logging
- AI malformed JSON → structured error log + user-visible error state; never crash
- Missing nutrients → display `~` prefix; show "estimated from macros" label
- Camera permission denied → show permission guidance sheet
- Notification permission denied → explain in Settings, no forced re-prompt
- Offline → serve from `URLCache` + in-memory generic food cache

---

## Testing

| Test File | Coverage |
|---|---|
| NutritionMathTests | Scale, kcal formula, BMR, TDEE, macro splits |
| MacroCalculatorTests | All 3 goals, non-negative macros, deficit/surplus |
| AIDecodingTests | Full schema decode, malformed JSON, low confidence |
| FoodRepositoryRoutingTests | Barcode → OFF, generic keyword → seed DB, custom → SwiftData |

---

## Security & Privacy

- API key stored in Keychain (`kSecClassGenericPassword`)
- No plaintext health data
- No analytics without explicit user toggle
- Local-only mode supported (AI features disabled if no key)
- Data export: export all logs as JSON
- Data delete: wipe all SwiftData stores

---

## Generic Foods Seed Format

`Resources/Seeds/generic_foods.json` — ~200 entries:

```json
{
  "id": "gf_banana",
  "name": "Banana",
  "aliases": ["bananas"],
  "category": "fruit",
  "kcalPer100g": 89,
  "proteinPer100g": 1.1,
  "carbsPer100g": 23.0,
  "fatPer100g": 0.3,
  "fiberPer100g": 2.6,
  "sugarPer100g": 12.2,
  "sodiumPer100mg": 1.0,
  "defaultServingGrams": 118
}
```

---

## HealthKit Integration (Feature-Flagged)

- Controlled by `UserProfile.appleHealthEnabled` (default: false)
- Reads: `HKQuantityType.bodyMass`
- Writes: `HKQuantityType.bodyMass`, `HKQuantityType.dietaryEnergyConsumed`
- Requires HealthKit entitlement + Info.plist usage strings
- All HealthKit calls wrapped in availability guard

---

## Setup Instructions

1. Create new Xcode project: iOS App, SwiftUI, Swift, minimum deployment iOS 17
2. Enable capabilities: HealthKit, Push Notifications
3. Add Info.plist keys: `NSCameraUsageDescription`, `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `NSUserNotificationsUsageDescription`
4. Add `generic_foods.json` to bundle resources
5. No third-party dependencies — all Apple frameworks only
6. Run unit tests before first build

---

END DESIGN DOCUMENT
