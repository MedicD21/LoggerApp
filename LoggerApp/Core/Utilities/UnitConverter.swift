import Foundation

enum UnitConverter {
    static func grams(
        amount: Double,
        unit: PortionUnit,
        defaultServingGrams: Double
    ) -> Double {
        switch unit {
        case .g:
            amount
        case .oz:
            amount * 28.3495
        case .lb:
            amount * 453.592
        case .cup:
            amount * max(defaultServingGrams, 240)
        case .tbsp:
            amount * max(defaultServingGrams, 15)
        case .piece:
            amount * max(defaultServingGrams, 1)
        case .ml:
            amount
        }
    }

    static func displayWeight(_ grams: Double) -> String {
        if grams >= 454 {
            return String(format: "%.2f lb", grams / 453.592)
        }
        if grams >= 28.35 {
            return String(format: "%.1f oz", grams / 28.3495)
        }
        return String(format: "%.0f g", grams)
    }
}

