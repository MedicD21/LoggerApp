import Foundation
import SwiftData

@MainActor
final class LogRepository: LogRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func summary(for date: Date, profile: UserProfile) throws -> DailyNutritionSummary {
        let entries = try entries(for: date)
        let total = entries.reduce(.zero) { $0 + $1.nutrition }
        let mealBreakdown = Dictionary(grouping: entries, by: \.meal)
            .mapValues { grouped in
                grouped.reduce(.zero) { $0 + $1.nutrition }
            }
        let weeklyAverageCalories = try weeklyAverageCalories(endingAt: date)

        return DailyNutritionSummary(
            date: date.startOfDay,
            total: total,
            targets: profile.resolvedMacroTargets,
            mealBreakdown: mealBreakdown,
            entries: entries,
            weeklyAverageCalories: weeklyAverageCalories
        )
    }

    func add(food: FoodItem, grams: Double, meal: MealSlot, note: String?) throws {
        let day = Date().startOfDay
        let log = try fetchOrCreateLog(for: day)
        let entry = LoggedFood(foodItem: food, amountGrams: grams, meal: meal, note: note)
        entry.dayLog = log
        log.entries.append(entry)
        modelContext.insert(entry)
        try modelContext.save()
    }

    func entries(for date: Date) throws -> [LoggedFood] {
        let day = date.startOfDay
        let descriptor = FetchDescriptor<FoodLog>(
            predicate: #Predicate { log in
                log.day == day
            }
        )
        let log = try modelContext.fetch(descriptor).first
        return (log?.entries ?? []).sorted(by: { $0.loggedAt < $1.loggedAt })
    }

    private func fetchOrCreateLog(for day: Date) throws -> FoodLog {
        let descriptor = FetchDescriptor<FoodLog>(
            predicate: #Predicate { log in
                log.day == day
            }
        )

        if let log = try modelContext.fetch(descriptor).first {
            return log
        }

        let log = FoodLog(day: day)
        modelContext.insert(log)
        return log
    }

    private func weeklyAverageCalories(endingAt date: Date) throws -> Double {
        let start = date.startOfDay.adding(days: -6)
        let end = date.startOfDay.adding(days: 1)
        let descriptor = FetchDescriptor<FoodLog>(
            predicate: #Predicate { log in
                log.day >= start && log.day < end
            }
        )
        let logs = try modelContext.fetch(descriptor)

        guard !logs.isEmpty else { return 0 }
        let totals = logs.map { log in
            log.entries.reduce(0) { partial, entry in
                partial + entry.nutrition.calories
            }
        }

        return totals.reduce(0, +) / Double(totals.count)
    }
}

