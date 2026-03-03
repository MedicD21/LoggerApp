import Foundation

@MainActor
final class MedicationViewModel: ObservableObject {
    @Published private(set) var schedule: MedicationSchedule?
    @Published private(set) var doses: [MedicationDose] = []
    @Published var errorMessage: String?

    private let repository: MedicationRepositoryProtocol

    init(repository: MedicationRepositoryProtocol) {
        self.repository = repository
    }

    func load() {
        do {
            schedule = try repository.currentSchedule()
            doses = try repository.recentDoses(limit: 8)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveSchedule(
        medicationName: String,
        doseDisplay: String,
        frequencyType: MedicationFrequencyType,
        intervalDays: Int,
        siteRotation: [String],
        nextDueDate: Date,
        remainingDoses: Int,
        refillReminderDaysAhead: Int
    ) {
        do {
            let schedule = MedicationSchedule(
                medicationName: medicationName,
                doseDisplay: doseDisplay,
                frequencyType: frequencyType,
                customIntervalDays: intervalDays,
                siteRotation: siteRotation,
                nextDueDate: nextDueDate,
                refillReminderDaysAhead: refillReminderDaysAhead,
                remainingDoses: remainingDoses
            )
            try repository.saveSchedule(schedule)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logDose(site: String, sideEffects: String?) {
        do {
            try repository.logDose(site: site, sideEffects: sideEffects)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

