import Foundation
import SwiftData

@Model
final class WeightEntry {
    var id: UUID
    var date: Date
    var value: Double
    var unitRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        unit: WeightUnit,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.value = value
        self.unitRaw = unit.rawValue
        self.createdAt = createdAt
    }

    var unit: WeightUnit {
        get { WeightUnit(rawValue: unitRaw) ?? .lb }
        set { unitRaw = newValue.rawValue }
    }

    var kilograms: Double {
        unit == .kg ? value : value * 0.45359237
    }

    var pounds: Double {
        unit == .lb ? value : value * 2.2046226218
    }
}
