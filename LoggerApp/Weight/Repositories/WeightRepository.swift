import Foundation
import SwiftData

@MainActor
final class WeightRepository: WeightRepositoryProtocol {
    private let modelContext: ModelContext
    private let healthKitService: HealthKitService

    init(modelContext: ModelContext, healthKitService: HealthKitService) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
    }

    func addWeight(value: Double, unit: WeightUnit, date: Date) throws {
        let entry = WeightEntry(date: date.startOfDay, value: value, unit: unit)
        modelContext.insert(entry)
        try modelContext.save()
    }

    func fetchWeights(days: Int = 90) throws -> [WeightEntry] {
        let start = Date().startOfDay.adding(days: -days)
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.date >= start
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }

    func sevenDayMovingAverage() throws -> [(date: Date, value: Double)] {
        let weights = try fetchWeights(days: 90)
        let values = weights.map { (date: $0.date, value: $0.kilograms) }
        return NutritionMath.movingAverage(values: values, window: 7)
    }

    func syncToHealthIfEnabled(profile: UserProfile, entry: WeightEntry) async {
        guard profile.appleHealthEnabled, healthKitService.isAvailable else { return }
        do {
            try await healthKitService.requestAuthorization()
            try await healthKitService.saveWeight(kilograms: entry.kilograms)
        } catch {
            // Keep local persistence authoritative if HealthKit sync is unavailable.
        }
    }
}

