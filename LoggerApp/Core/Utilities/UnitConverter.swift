import Foundation

enum UnitConverter {
    static let gramsPerOunce = 28.3495
    static let gramsPerPound = 453.592
    static let poundsPerKilogram = 2.2046226218
    static let centimetersPerInch = 2.54

    static func grams(
        amount: Double,
        unit: PortionUnit,
        defaultServingGrams: Double
    ) -> Double {
        switch unit {
        case .g:
            amount
        case .oz:
            amount * gramsPerOunce
        case .lb:
            amount * gramsPerPound
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
        if grams >= gramsPerPound {
            return "\( (grams / gramsPerPound).decimalString(maxFractionDigits: 2) ) lb"
        }
        let ounces = grams / gramsPerOunce
        return "\(ounces.decimalString(maxFractionDigits: 2)) oz"
    }

    static func ounces(fromGrams grams: Double) -> Double {
        grams / gramsPerOunce
    }

    static func pounds(fromKilograms kilograms: Double) -> Double {
        kilograms * poundsPerKilogram
    }

    static func kilograms(fromPounds pounds: Double) -> Double {
        pounds / poundsPerKilogram
    }

    static func centimeters(feet: Int, inches: Int) -> Double {
        (Double((feet * 12) + inches)) * centimetersPerInch
    }

    static func feetAndInches(fromCentimeters centimeters: Double) -> (feet: Int, inches: Int) {
        let totalInches = Int((centimeters / centimetersPerInch).rounded())
        return (feet: totalInches / 12, inches: totalInches % 12)
    }

    static func caloriesPerThreePointFiveOunces(kcalPer100g: Double?) -> Int {
        let grams = 3.5 * gramsPerOunce
        let kcal = ((kcalPer100g ?? 0) / 100) * grams
        return Int(kcal.rounded())
    }

    static func per100Grams(fromPerThreePointFiveOunces value: Double) -> Double {
        let grams = 3.5 * gramsPerOunce
        return (value / grams) * 100
    }
}
