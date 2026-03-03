import Foundation

enum NutritionMath {
    static func scale(nutrient: Double, per100g: Double, amountGrams: Double) -> Double {
        guard per100g > 0, amountGrams >= 0 else { return 0 }
        return (nutrient / per100g) * amountGrams
    }

    static func computedKcal(protein: Double, carbs: Double, fat: Double) -> Double {
        (protein * 4) + (carbs * 4) + (fat * 9)
    }

    static func bmr(weightKg: Double, heightCm: Double, ageYears: Int, sex: BiologicalSex) -> Double {
        (10 * weightKg) + (6.25 * heightCm) - (5 * Double(ageYears)) + sex.bmrAdjustment
    }

    static func tdee(bmr: Double, activityLevel: ActivityLevel) -> Double {
        bmr * activityLevel.multiplier
    }

    static func macroTargets(tdee: Double, goal: NutritionGoal) -> MacroTargets {
        let adjustedCalories = max(1_200, tdee + goal.calorieAdjustment)
        let split: (protein: Double, carbs: Double, fat: Double)

        switch goal {
        case .cut:
            split = (0.40, 0.35, 0.25)
        case .maintain:
            split = (0.30, 0.40, 0.30)
        case .bulk:
            split = (0.25, 0.50, 0.25)
        }

        return MacroTargets(
            calories: adjustedCalories.rounded(),
            proteinGrams: ((adjustedCalories * split.protein) / 4).rounded(),
            carbGrams: ((adjustedCalories * split.carbs) / 4).rounded(),
            fatGrams: ((adjustedCalories * split.fat) / 9).rounded()
        )
    }

    static func movingAverage(values: [(date: Date, value: Double)], window: Int) -> [(date: Date, value: Double)] {
        guard window > 0 else { return [] }

        return values.indices.compactMap { index in
            let lowerBound = max(0, index - window + 1)
            let slice = values[lowerBound...index]
            let average = slice.map(\.value).reduce(0, +) / Double(slice.count)
            return (date: values[index].date, value: average)
        }
    }
}

