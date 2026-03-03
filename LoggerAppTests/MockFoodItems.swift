import Foundation
@testable import LoggerApp

enum MockFoodItems {
    static let genericSeeds: [GenericFoodSeed] = [
        GenericFoodSeed(
            name: "Banana",
            brand: nil,
            barcode: nil,
            category: "generic",
            kcalPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 22.8,
            fatPer100g: 0.3,
            fiberPer100g: 2.6,
            sugarPer100g: 12.2,
            sodiumMgPer100g: 1,
            defaultServingGrams: 118
        ),
        GenericFoodSeed(
            name: "Chicken Breast, Cooked",
            brand: nil,
            barcode: nil,
            category: "generic",
            kcalPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6,
            fiberPer100g: 0,
            sugarPer100g: 0,
            sodiumMgPer100g: 74,
            defaultServingGrams: 120
        ),
    ]
}

