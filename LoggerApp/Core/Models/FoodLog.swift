import Foundation
import SwiftData

@Model
final class FoodLog {
    var id: UUID
    var day: Date
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LoggedFood.dayLog)
    var entries: [LoggedFood]

    init(
        id: UUID = UUID(),
        day: Date,
        createdAt: Date = .now,
        entries: [LoggedFood] = []
    ) {
        self.id = id
        self.day = day.startOfDay
        self.createdAt = createdAt
        self.entries = entries
    }
}

@Model
final class LoggedFood {
    var id: UUID
    var amountGrams: Double
    var mealRaw: String
    var loggedAt: Date
    var note: String?

    @Relationship(deleteRule: .nullify)
    var foodItem: FoodItem?

    var dayLog: FoodLog?

    init(
        id: UUID = UUID(),
        foodItem: FoodItem,
        amountGrams: Double,
        meal: MealSlot,
        loggedAt: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.foodItem = foodItem
        self.amountGrams = amountGrams
        self.mealRaw = meal.rawValue
        self.loggedAt = loggedAt
        self.note = note
    }

    var meal: MealSlot {
        get { MealSlot(rawValue: mealRaw) ?? .snack }
        set { mealRaw = newValue.rawValue }
    }

    var nutrition: NutritionSnapshot {
        foodItem?.nutrition(for: amountGrams) ?? .zero
    }
}

