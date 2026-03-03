import Foundation

enum OFFResponseParser {
    static func normalize(product: OFFProduct) -> FoodItem? {
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return nil }

        let protein = product.nutriments.proteins100g ?? product.nutriments.proteinsServing
        let carbs = product.nutriments.carbohydrates100g ?? product.nutriments.carbohydratesServing
        let fat = product.nutriments.fat100g ?? product.nutriments.fatServing
        let explicitKcal = product.nutriments.kcal100g ?? product.nutriments.kcalServing
        let estimated = explicitKcal == nil
        let kcal = explicitKcal ?? NutritionMath.computedKcal(
            protein: protein ?? 0,
            carbs: carbs ?? 0,
            fat: fat ?? 0
        )

        let servingGrams = product.servingQuantity
            ?? product.servingSize?.extractServingGrams()
            ?? 100

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
            fiberPer100g: product.nutriments.fiber100g,
            sugarPer100g: product.nutriments.sugars100g,
            sodiumMgPer100g: product.nutriments.sodium100g.map { $0 * 1_000 },
            isKcalEstimated: estimated,
            defaultServingGrams: max(servingGrams, 1)
        )
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

