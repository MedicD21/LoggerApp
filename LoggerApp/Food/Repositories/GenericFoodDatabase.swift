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
        let normalizedQuery = Self.normalizedTokens(query)
        guard !normalizedQuery.isEmpty else { return [] }

        return items
            .compactMap { item -> (score: Int, item: GenericFoodSeed)? in
                let score = Self.score(seed: item, query: normalizedQuery, rawQuery: query)
                guard score > 0 else { return nil }
                return (score: score, item: item)
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.item.name < rhs.item.name
                }
                return lhs.score > rhs.score
            }
            .prefix(20)
            .map { Self.makeFoodItem(seed: $0.item) }
    }

    func containsCommonFoodMatch(_ query: String) -> Bool {
        !search(query).isEmpty
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

    private static func score(seed: GenericFoodSeed, query: [String], rawQuery: String) -> Int {
        let haystack = "\(seed.name) \(seed.brand ?? "")"
        let haystackTokens = Set(normalizedTokens(haystack))
        let querySet = Set(query)

        let overlap = querySet.intersection(haystackTokens)
        guard !overlap.isEmpty else {
            let compactHaystack = normalizedString(haystack)
            let compactQuery = normalizedString(rawQuery)
            return compactHaystack.contains(compactQuery) ? 50 : 0
        }

        var score = overlap.count * 20
        let compactHaystack = normalizedString(haystack)
        let compactQuery = normalizedString(rawQuery)

        if compactHaystack == compactQuery {
            score += 120
        } else if compactHaystack.contains(compactQuery) {
            score += 60
        }

        if haystackTokens.isSuperset(of: querySet) {
            score += 30
        }

        if let first = query.first, haystackTokens.contains(first) {
            score += 10
        }

        return score
    }

    private static func normalizedString(_ value: String) -> String {
        normalizedTokens(value).joined(separator: " ")
    }

    private static func normalizedTokens(_ value: String) -> [String] {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map(singularize(token:))
    }

    private static func singularize(token: String) -> String {
        guard token.count > 3 else { return token }
        if token.hasSuffix("ies") {
            return String(token.dropLast(3)) + "y"
        }
        if token.hasSuffix("es") {
            return String(token.dropLast())
        }
        if token.hasSuffix("s") {
            return String(token.dropLast())
        }
        return token
    }
}
