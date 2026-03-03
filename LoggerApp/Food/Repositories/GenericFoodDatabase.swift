import Foundation

struct GenericFoodDatabase {
    private let items: [GenericFoodSeed]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "generic_foods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([GenericFoodSeed].self, from: data) else {
            self.items = []
            return
        }

        self.items = items
    }

    init(items: [GenericFoodSeed]) {
        self.items = items
    }

    func search(_ query: String) -> [FoodItem] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let tokens = query.lowercased().split(separator: " ").map(String.init)
        return items
            .filter { item in
                let haystack = "\(item.name) \(item.brand ?? "")".lowercased()
                return tokens.allSatisfy(haystack.contains(_:))
            }
            .prefix(20)
            .map(Self.makeFoodItem(seed:))
    }

    func containsCommonFoodMatch(_ query: String) -> Bool {
        let normalized = query.lowercased()
        return items.contains { normalized.contains($0.name.lowercased()) || $0.name.lowercased().contains(normalized) }
    }

    private static func makeFoodItem(seed: GenericFoodSeed) -> FoodItem {
        FoodItem(
            name: seed.name,
            brand: seed.brand,
            barcode: seed.barcode,
            source: .generic,
            category: .generic,
            kcalPer100g: seed.kcalPer100g,
            proteinPer100g: seed.proteinPer100g,
            carbsPer100g: seed.carbsPer100g,
            fatPer100g: seed.fatPer100g,
            fiberPer100g: seed.fiberPer100g,
            sugarPer100g: seed.sugarPer100g,
            sodiumMgPer100g: seed.sodiumMgPer100g,
            isKcalEstimated: seed.kcalPer100g == nil,
            defaultServingGrams: seed.defaultServingGrams
        )
    }
}

