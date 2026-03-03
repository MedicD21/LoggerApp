import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var onboardingCompleted: Bool
    var weightKg: Double
    var heightCm: Double
    var ageYears: Int
    var sexRaw: String
    var activityLevelRaw: String
    var goalRaw: String
    var customCalorieTarget: Double?
    var customProteinTarget: Double?
    var customCarbTarget: Double?
    var customFatTarget: Double?
    var appleHealthEnabled: Bool
    var localOnlyMode: Bool
    var aiEnabled: Bool
    var mealReminderEnabled: Bool
    var proteinReminderEnabled: Bool
    var weighInReminderEnabled: Bool
    var medicationReminderEnabled: Bool
    var hydrationReminderEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        onboardingCompleted: Bool = false,
        weightKg: Double = 82,
        heightCm: Double = 178,
        ageYears: Int = 35,
        sex: BiologicalSex = .male,
        activityLevel: ActivityLevel = .moderatelyActive,
        goal: NutritionGoal = .maintain,
        customCalorieTarget: Double? = nil,
        customProteinTarget: Double? = nil,
        customCarbTarget: Double? = nil,
        customFatTarget: Double? = nil,
        appleHealthEnabled: Bool = false,
        localOnlyMode: Bool = false,
        aiEnabled: Bool = true,
        mealReminderEnabled: Bool = true,
        proteinReminderEnabled: Bool = true,
        weighInReminderEnabled: Bool = true,
        medicationReminderEnabled: Bool = true,
        hydrationReminderEnabled: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.onboardingCompleted = onboardingCompleted
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.ageYears = ageYears
        self.sexRaw = sex.rawValue
        self.activityLevelRaw = activityLevel.rawValue
        self.goalRaw = goal.rawValue
        self.customCalorieTarget = customCalorieTarget
        self.customProteinTarget = customProteinTarget
        self.customCarbTarget = customCarbTarget
        self.customFatTarget = customFatTarget
        self.appleHealthEnabled = appleHealthEnabled
        self.localOnlyMode = localOnlyMode
        self.aiEnabled = aiEnabled
        self.mealReminderEnabled = mealReminderEnabled
        self.proteinReminderEnabled = proteinReminderEnabled
        self.weighInReminderEnabled = weighInReminderEnabled
        self.medicationReminderEnabled = medicationReminderEnabled
        self.hydrationReminderEnabled = hydrationReminderEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .moderatelyActive }
        set { activityLevelRaw = newValue.rawValue }
    }

    var goal: NutritionGoal {
        get { NutritionGoal(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }

    var resolvedMacroTargets: MacroTargets {
        if let customCalorieTarget,
           let customProteinTarget,
           let customCarbTarget,
           let customFatTarget {
            return MacroTargets(
                calories: customCalorieTarget,
                proteinGrams: customProteinTarget,
                carbGrams: customCarbTarget,
                fatGrams: customFatTarget
            )
        }

        let bmr = NutritionMath.bmr(
            weightKg: weightKg,
            heightCm: heightCm,
            ageYears: ageYears,
            sex: sex
        )

        let tdee = NutritionMath.tdee(
            bmr: bmr,
            activityLevel: activityLevel
        )

        return NutritionMath.macroTargets(tdee: tdee, goal: goal)
    }

    var weightPounds: Double {
        UnitConverter.pounds(fromKilograms: weightKg)
    }

    var heightFeetAndInches: (feet: Int, inches: Int) {
        UnitConverter.feetAndInches(fromCentimeters: heightCm)
    }
}
