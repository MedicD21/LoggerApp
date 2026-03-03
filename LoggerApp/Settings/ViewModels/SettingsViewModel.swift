import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published private(set) var hasAPIKey: Bool
    @Published var exportURL: URL?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
        self.hasAPIKey = container.anthropicClient.hasAPIKey()
    }

    func saveAPIKey(_ key: String) {
        do {
            try container.anthropicClient.saveAPIKey(key)
            hasAPIKey = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        container.anthropicClient.removeAPIKey()
        hasAPIKey = false
    }

    func completeOnboarding(
        weightKg: Double,
        heightCm: Double,
        ageYears: Int,
        sex: BiologicalSex,
        activityLevel: ActivityLevel,
        goal: NutritionGoal
    ) {
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? container.modelContext.fetch(descriptor).first {
            profile.onboardingCompleted = true
            profile.weightKg = weightKg
            profile.heightCm = heightCm
            profile.ageYears = ageYears
            profile.sex = sex
            profile.activityLevel = activityLevel
            profile.goal = goal
            profile.updatedAt = .now
        } else {
            let profile = UserProfile(
                onboardingCompleted: true,
                weightKg: weightKg,
                heightCm: heightCm,
                ageYears: ageYears,
                sex: sex,
                activityLevel: activityLevel,
                goal: goal
            )
            container.modelContext.insert(profile)
        }

        container.save()
    }

    func refreshNotifications(profile: UserProfile) async {
        do {
            let medication = try container.medicationRepository.currentSchedule()
            let profileSnapshot = NotificationProfileSnapshot(profile: profile)
            let medicationSnapshot = medication.map(MedicationReminderSnapshot.init)
            try await container.notificationManager.refreshNotifications(
                profile: profileSnapshot,
                medication: medicationSnapshot
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func exportData() {
        do {
            let payload = try ExportPayload.make(from: container.modelContext)
            let data = try JSONEncoder.prettyPrinted.encode(payload)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LoggerAppExport-\(ISO8601DateFormatter().string(from: .now)).json")
            try data.write(to: url, options: .atomic)
            exportURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAllData() {
        do {
            try wipe(FetchDescriptor<LoggedFood>())
            try wipe(FetchDescriptor<FoodLog>())
            try wipe(FetchDescriptor<FoodItem>())
            try wipe(FetchDescriptor<WeightEntry>())
            try wipe(FetchDescriptor<MedicationDose>())
            try wipe(FetchDescriptor<MedicationSchedule>())
            try wipe(FetchDescriptor<UserProfile>())
            container.anthropicClient.removeAPIKey()
            hasAPIKey = false
            container.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func wipe<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws {
        let objects = try container.modelContext.fetch(descriptor)
        for object in objects {
            container.modelContext.delete(object)
        }
    }
}

private struct ExportPayload: Codable {
    struct FoodDTO: Codable {
        let name: String
        let brand: String?
        let barcode: String?
        let source: String
    }

    struct LogDTO: Codable {
        let foodName: String
        let grams: Double
        let meal: String
        let loggedAt: Date
    }

    struct WeightDTO: Codable {
        let date: Date
        let value: Double
        let unit: String
    }

    struct MedicationDTO: Codable {
        let medicationName: String
        let nextDueDate: Date
        let remainingDoses: Int
    }

    let exportedAt: Date
    let foods: [FoodDTO]
    let logs: [LogDTO]
    let weights: [WeightDTO]
    let medications: [MedicationDTO]

    static func make(from context: ModelContext) throws -> ExportPayload {
        let foods = try context.fetch(FetchDescriptor<FoodItem>())
        let logs = try context.fetch(FetchDescriptor<LoggedFood>())
        let weights = try context.fetch(FetchDescriptor<WeightEntry>())
        let medications = try context.fetch(FetchDescriptor<MedicationSchedule>())

        return ExportPayload(
            exportedAt: .now,
            foods: foods.map { FoodDTO(name: $0.name, brand: $0.brand, barcode: $0.barcode, source: $0.source.rawValue) },
            logs: logs.map {
                LogDTO(
                    foodName: $0.foodItem?.displayName ?? "Unknown",
                    grams: $0.amountGrams,
                    meal: $0.meal.rawValue,
                    loggedAt: $0.loggedAt
                )
            },
            weights: weights.map { WeightDTO(date: $0.date, value: $0.value, unit: $0.unit.rawValue) },
            medications: medications.map {
                MedicationDTO(
                    medicationName: $0.medicationName,
                    nextDueDate: $0.nextDueDate,
                    remainingDoses: $0.remainingDoses
                )
            }
        )
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
