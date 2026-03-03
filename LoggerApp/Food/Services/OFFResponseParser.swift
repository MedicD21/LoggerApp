import Foundation

enum OFFResponseParser {
    static func normalize(product: OFFProduct) -> FoodItem? {
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return nil }

        let servingGrams = max(
            product.servingSize?.extractServingGrams()
                ?? product.servingQuantity
                ?? 100,
            1
        )
        let nutritionBasis = NutritionBasis(rawValue: product.nutritionDataPer)

        let protein = normalizedPer100Value(
            explicit100g: product.nutriments.proteins100g,
            perServing: product.nutriments.proteinsServing,
            fallback: product.nutriments.proteins,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let carbs = normalizedPer100Value(
            explicit100g: product.nutriments.carbohydrates100g,
            perServing: product.nutriments.carbohydratesServing,
            fallback: product.nutriments.carbohydrates,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let fat = normalizedPer100Value(
            explicit100g: product.nutriments.fat100g,
            perServing: product.nutriments.fatServing,
            fallback: product.nutriments.fat,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let fiber = normalizedPer100Value(
            explicit100g: product.nutriments.fiber100g,
            perServing: product.nutriments.fiberServing,
            fallback: product.nutriments.fiber,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let sugars = normalizedPer100Value(
            explicit100g: product.nutriments.sugars100g,
            perServing: product.nutriments.sugarsServing,
            fallback: product.nutriments.sugars,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let sodium = normalizedPer100Value(
            explicit100g: product.nutriments.sodium100g,
            perServing: product.nutriments.sodiumServing,
            fallback: product.nutriments.sodium,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let explicitKcal = normalizedPer100Value(
            explicit100g: product.nutriments.kcal100g,
            perServing: product.nutriments.kcalServing,
            fallback: product.nutriments.kcal,
            nutritionBasis: nutritionBasis,
            servingGrams: servingGrams
        )
        let estimated = explicitKcal == nil
        let kcal = explicitKcal ?? NutritionMath.computedKcal(
            protein: protein ?? 0,
            carbs: carbs ?? 0,
            fat: fat ?? 0
        )

        return FoodItem(
            name: name,
            brand: product.brands,
            barcode: product.code,
            source: .off,
            category: .packaged,
            kcalPer100g: kcal,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: fiber,
            sugarPer100g: sugars,
            sodiumMgPer100g: sodium.map { $0 * 1_000 },
            isKcalEstimated: estimated,
            defaultServingGrams: max(servingGrams, 1)
        )
    }

    private static func normalizedPer100Value(
        explicit100g: Double?,
        perServing: Double?,
        fallback: Double?,
        nutritionBasis: NutritionBasis,
        servingGrams: Double
    ) -> Double? {
        if let explicit100g {
            return explicit100g
        }

        if let perServing, servingGrams > 0 {
            return perServing * 100 / servingGrams
        }

        guard let fallback else { return nil }

        switch nutritionBasis {
        case .perServing:
            return servingGrams > 0 ? (fallback * 100 / servingGrams) : fallback
        case .per100g, .unknown:
            return fallback
        }
    }
}

private enum NutritionBasis {
    case per100g
    case perServing
    case unknown

    init(rawValue: String?) {
        switch rawValue?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "100g":
            self = .per100g
        case "serving":
            self = .perServing
        default:
            self = .unknown
        }
    }
}

private extension String {
    func extractServingGrams() -> Double? {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*g"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(
                in: self,
                options: [],
                range: NSRange(startIndex..<endIndex, in: self)
              ),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }

        return Double(self[range])
    }
}
