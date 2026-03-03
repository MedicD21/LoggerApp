import Foundation
import SwiftData

@Model
final class MedicationSchedule {
    var id: UUID
    var medicationName: String
    var doseDisplay: String
    var frequencyTypeRaw: String
    var customIntervalDays: Int
    var siteRotationCSV: String
    var nextDueDate: Date
    var refillReminderDaysAhead: Int
    var remainingDoses: Int
    var refillReminderThreshold: Int
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MedicationDose.schedule)
    var doses: [MedicationDose]

    init(
        id: UUID = UUID(),
        medicationName: String,
        doseDisplay: String,
        frequencyType: MedicationFrequencyType,
        customIntervalDays: Int = 7,
        siteRotation: [String],
        nextDueDate: Date,
        refillReminderDaysAhead: Int = 7,
        remainingDoses: Int = 4,
        refillReminderThreshold: Int = 1,
        isActive: Bool = true,
        createdAt: Date = .now,
        doses: [MedicationDose] = []
    ) {
        self.id = id
        self.medicationName = medicationName
        self.doseDisplay = doseDisplay
        self.frequencyTypeRaw = frequencyType.rawValue
        self.customIntervalDays = customIntervalDays
        self.siteRotationCSV = siteRotation.joined(separator: ",")
        self.nextDueDate = nextDueDate
        self.refillReminderDaysAhead = refillReminderDaysAhead
        self.remainingDoses = remainingDoses
        self.refillReminderThreshold = refillReminderThreshold
        self.isActive = isActive
        self.createdAt = createdAt
        self.doses = doses
    }

    var frequencyType: MedicationFrequencyType {
        get { MedicationFrequencyType(rawValue: frequencyTypeRaw) ?? .weekly }
        set { frequencyTypeRaw = newValue.rawValue }
    }

    var intervalDays: Int {
        frequencyType == .weekly ? 7 : max(1, customIntervalDays)
    }

    var siteRotation: [String] {
        get {
            siteRotationCSV
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            siteRotationCSV = newValue.joined(separator: ",")
        }
    }

    var nextSuggestedSite: String {
        let sites = siteRotation
        guard !sites.isEmpty else { return "Not set" }
        return sites[doses.count % sites.count]
    }
}

@Model
final class MedicationDose {
    var id: UUID
    var administeredAt: Date
    var site: String
    var sideEffects: String?
    var createdAt: Date

    var schedule: MedicationSchedule?

    init(
        id: UUID = UUID(),
        administeredAt: Date = .now,
        site: String,
        sideEffects: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.administeredAt = administeredAt
        self.site = site
        self.sideEffects = sideEffects
        self.createdAt = createdAt
    }
}

