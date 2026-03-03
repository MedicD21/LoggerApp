import Foundation

enum FoodSource: String, Codable, CaseIterable, Identifiable {
    case off
    case usda
    case generic
    case custom
    case recipe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off:
            "Open Food Facts"
        case .usda:
            "USDA"
        case .generic:
            "Generic DB"
        case .custom:
            "Custom"
        case .recipe:
            "Recipe"
        }
    }

    var systemImage: String {
        switch self {
        case .off:
            "shippingbox"
        case .usda:
            "leaf"
        case .generic:
            "fork.knife"
        case .custom:
            "square.and.pencil"
        case .recipe:
            "book.closed"
        }
    }
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case generic
    case packaged
    case recipe

    var id: String { rawValue }
}

enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum PortionUnit: String, Codable, CaseIterable, Identifiable {
    case g
    case oz
    case lb
    case cup
    case tbsp
    case piece
    case ml

    var id: String { rawValue }

    var title: String {
        switch self {
        case .g: "g"
        case .oz: "oz"
        case .lb: "lb"
        case .cup: "cup"
        case .tbsp: "tbsp"
        case .piece: "piece"
        case .ml: "ml"
        }
    }

    static var imperialFirstCases: [PortionUnit] {
        [.oz, .lb, .cup, .tbsp, .piece, .ml, .g]
    }
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case female
    case male

    var id: String { rawValue }

    var bmrAdjustment: Double {
        switch self {
        case .female: -161
        case .male: 5
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case athlete

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .lightlyActive: 1.375
        case .moderatelyActive: 1.55
        case .veryActive: 1.725
        case .athlete: 1.9
        }
    }

    var title: String {
        switch self {
        case .sedentary: "Sedentary"
        case .lightlyActive: "Lightly Active"
        case .moderatelyActive: "Moderately Active"
        case .veryActive: "Very Active"
        case .athlete: "Athlete"
        }
    }
}

enum NutritionGoal: String, Codable, CaseIterable, Identifiable {
    case cut
    case maintain
    case bulk

    var id: String { rawValue }

    var calorieAdjustment: Double {
        switch self {
        case .cut: -500
        case .maintain: 0
        case .bulk: 300
        }
    }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }
}

enum MedicationFrequencyType: String, Codable, CaseIterable, Identifiable {
    case weekly
    case custom

    var id: String { rawValue }
}

struct NutritionSnapshot: Codable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodiumMg: Double

    static let zero = NutritionSnapshot(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodiumMg: 0
    )

    static func + (lhs: NutritionSnapshot, rhs: NutritionSnapshot) -> NutritionSnapshot {
        NutritionSnapshot(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat,
            fiber: lhs.fiber + rhs.fiber,
            sugar: lhs.sugar + rhs.sugar,
            sodiumMg: lhs.sodiumMg + rhs.sodiumMg
        )
    }
}

struct MacroTargets: Codable, Hashable {
    var calories: Double
    var proteinGrams: Double
    var carbGrams: Double
    var fatGrams: Double
}

struct DailyNutritionSummary: Hashable {
    var date: Date
    var total: NutritionSnapshot
    var targets: MacroTargets
    var mealBreakdown: [MealSlot: NutritionSnapshot]
    var entries: [LoggedFood]
    var weeklyAverageCalories: Double
}

struct AIInsightContext: Codable, Sendable {
    let date: Date
    let total: NutritionSnapshot
    let targets: MacroTargets
    let weeklyAverageCalories: Double
    let usesCustomTargets: Bool
    let goal: String
}

struct WeeklyInsight: Identifiable, Hashable {
    enum Source: String, Codable, Hashable {
        case local
        case ai
    }

    let id = UUID()
    let title: String
    let detail: String
    let source: Source
}

struct GenericFoodSeed: Codable, Hashable {
    let name: String
    let brand: String?
    let barcode: String?
    let category: String
    let kcalPer100g: Double?
    let proteinPer100g: Double?
    let carbsPer100g: Double?
    let fatPer100g: Double?
    let fiberPer100g: Double?
    let sugarPer100g: Double?
    let sodiumMgPer100g: Double?
    let defaultServingGrams: Double
}

enum FoodLookupRoute: Equatable {
    case barcode
    case generic
    case custom
    case packagedSearch
}
