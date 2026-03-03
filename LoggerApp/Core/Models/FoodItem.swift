import Foundation
import SwiftData

@Model
final class FoodItem {
    var id: UUID
    var name: String
    var brand: String?
    var barcode: String?
    var sourceRaw: String
    var categoryRaw: String
    var kcalPer100g: Double?
    var proteinPer100g: Double?
    var carbsPer100g: Double?
    var fatPer100g: Double?
    var fiberPer100g: Double?
    var sugarPer100g: Double?
    var sodiumMgPer100g: Double?
    var isKcalEstimated: Bool
    var defaultServingGrams: Double
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        source: FoodSource,
        category: FoodCategory,
        kcalPer100g: Double?,
        proteinPer100g: Double?,
        carbsPer100g: Double?,
        fatPer100g: Double?,
        fiberPer100g: Double? = nil,
        sugarPer100g: Double? = nil,
        sodiumMgPer100g: Double? = nil,
        isKcalEstimated: Bool = false,
        defaultServingGrams: Double,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.sourceRaw = source.rawValue
        self.categoryRaw = category.rawValue
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumMgPer100g = sodiumMgPer100g
        self.isKcalEstimated = isKcalEstimated
        self.defaultServingGrams = defaultServingGrams
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var source: FoodSource {
        get { FoodSource(rawValue: sourceRaw) ?? .custom }
        set { sourceRaw = newValue.rawValue }
    }

    var category: FoodCategory {
        get { FoodCategory(rawValue: categoryRaw) ?? .generic }
        set { categoryRaw = newValue.rawValue }
    }

    var displayName: String {
        if let brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }

    func nutrition(for grams: Double) -> NutritionSnapshot {
        let calories = kcalPer100g
            ?? NutritionMath.computedKcal(
                protein: proteinPer100g ?? 0,
                carbs: carbsPer100g ?? 0,
                fat: fatPer100g ?? 0
            )

        return NutritionSnapshot(
            calories: NutritionMath.scale(nutrient: calories, per100g: 100, amountGrams: grams),
            protein: NutritionMath.scale(nutrient: proteinPer100g ?? 0, per100g: 100, amountGrams: grams),
            carbs: NutritionMath.scale(nutrient: carbsPer100g ?? 0, per100g: 100, amountGrams: grams),
            fat: NutritionMath.scale(nutrient: fatPer100g ?? 0, per100g: 100, amountGrams: grams),
            fiber: NutritionMath.scale(nutrient: fiberPer100g ?? 0, per100g: 100, amountGrams: grams),
            sugar: NutritionMath.scale(nutrient: sugarPer100g ?? 0, per100g: 100, amountGrams: grams),
            sodiumMg: NutritionMath.scale(nutrient: sodiumMgPer100g ?? 0, per100g: 100, amountGrams: grams)
        )
    }
}

