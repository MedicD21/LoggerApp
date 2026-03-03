import Foundation
import SwiftData

@MainActor
final class MedicationRepository: MedicationRepositoryProtocol {
    private let modelContext: ModelContext
    private let notificationManager: NotificationManager

    init(modelContext: ModelContext, notificationManager: NotificationManager) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager
    }

    func currentSchedule() throws -> MedicationSchedule? {
        let descriptor = FetchDescriptor<MedicationSchedule>(
            predicate: #Predicate { schedule in
                schedule.isActive
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    func saveSchedule(_ schedule: MedicationSchedule) throws {
        if let current = try currentSchedule(), current.id != schedule.id {
            current.isActive = false
        }

        if modelContext.model(for: schedule.persistentModelID) == nil {
            modelContext.insert(schedule)
        }

        try modelContext.save()
        Task { await notificationManager.scheduleMedicationNotifications(for: schedule) }
    }

    func logDose(site: String, sideEffects: String?) throws {
        guard let schedule = try currentSchedule() else { return }
        let dose = MedicationDose(site: site, sideEffects: sideEffects)
        dose.schedule = schedule
        schedule.doses.append(dose)
        schedule.nextDueDate = max(Date(), schedule.nextDueDate).adding(days: schedule.intervalDays)
        schedule.remainingDoses = max(schedule.remainingDoses - 1, 0)
        modelContext.insert(dose)
        try modelContext.save()
        Task { await notificationManager.scheduleMedicationNotifications(for: schedule) }
    }

    func recentDoses(limit: Int = 8) throws -> [MedicationDose] {
        var descriptor = FetchDescriptor<MedicationDose>(
            sortBy: [SortDescriptor(\.administeredAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
}

