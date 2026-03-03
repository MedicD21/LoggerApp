import Foundation
import OSLog
import SwiftData

@MainActor
final class FoodRepository: FoodRepositoryProtocol {
    private let logger = Logger(subsystem: "LoggerApp", category: "FoodRepository")
    private let modelContext: ModelContext
    private let genericDatabase: GenericFoodDatabase
    private let offClient: OFFClient
    private let usdaClient: USDAClient

    init(
        modelContext: ModelContext,
        genericDatabase: GenericFoodDatabase,
        offClient: OFFClient,
        usdaClient: USDAClient
    ) {
        self.modelContext = modelContext
        self.genericDatabase = genericDatabase
        self.offClient = offClient
        self.usdaClient = usdaClient
    }

    nonisolated static func determineRoute(
        query: String?,
        barcode: String?,
        aiCategory: FoodCategory? = nil,
        genericDatabase: GenericFoodDatabase
    ) -> FoodLookupRoute {
        if let barcode, !barcode.isEmpty {
            return .barcode
        }

        if aiCategory == .packaged {
            return .packagedSearch
        }

        guard let query = query?.trimmingCharacters(in: .whitespacesAndNewlines),
              !query.isEmpty else {
            return .custom
        }

        if genericDatabase.containsCommonFoodMatch(query) {
            return .generic
        }

        return .packagedSearch
    }

    func search(query: String, preferredCategory: FoodCategory? = nil) async throws -> [FoodItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let intent = searchIntent(for: trimmed, preferredCategory: preferredCategory)
        let custom = try cachedCustomFoods(matching: trimmed)
        let genericSeeds = genericDatabase.search(trimmed)

        let usdaGenericResult = await remoteSearchIfNeeded(intent.shouldSearchGeneric) {
            try await self.usdaClient.searchGenericFoods(trimmed)
        }
        let offPackagedResult = await remoteSearchIfNeeded(intent.shouldSearchPackaged) {
            try await self.offClient.searchByName(trimmed)
        }
        let usdaPackagedResult = await remoteSearchIfNeeded(intent.shouldSearchPackaged) {
            try await self.usdaClient.searchPackagedFoods(trimmed)
        }

        let usdaGeneric = try resolvedRemoteItems(
            from: usdaGenericResult,
            cacheSources: [.usda],
            cacheCategories: [.generic],
            fallbackQuery: trimmed,
            failureMessage: "USDA generic search failed"
        )
        let offPackaged = try resolvedRemoteItems(
            from: offPackagedResult,
            cacheSources: [.off],
            cacheCategories: [.packaged],
            fallbackQuery: trimmed,
            failureMessage: "OFF search failed"
        )
        let usdaPackaged = try resolvedRemoteItems(
            from: usdaPackagedResult,
            cacheSources: [.usda],
            cacheCategories: [.packaged],
            fallbackQuery: trimmed,
            failureMessage: "USDA branded search failed"
        )

        return mergeAndRank(
            custom + genericSeeds + usdaGeneric + offPackaged + usdaPackaged,
            query: trimmed,
            preferredCategory: preferredCategory,
            intent: intent
        )
    }

    func fetchByBarcode(_ barcode: String) async throws -> [FoodItem] {
        let route = Self.determineRoute(query: nil, barcode: barcode, genericDatabase: genericDatabase)
        guard route == .barcode else { return [] }

        do {
            let items = try await offClient.fetchByBarcode(barcode)
            try cache(items: items)
            return items
        } catch {
            logger.error("OFF barcode lookup failed; using cache: \(String(describing: error), privacy: .public)")
            let descriptor = FetchDescriptor<FoodItem>(
                predicate: #Predicate { item in
                    item.barcode == barcode
                }
            )
            return try modelContext.fetch(descriptor)
        }
    }

    func upsertCustomFood(_ item: FoodItem) throws {
        if let existing = try existingCustomFood(named: item.name, brand: item.brand) {
            existing.barcode = item.barcode
            existing.category = item.category
            existing.kcalPer100g = item.kcalPer100g
            existing.proteinPer100g = item.proteinPer100g
            existing.carbsPer100g = item.carbsPer100g
            existing.fatPer100g = item.fatPer100g
            existing.fiberPer100g = item.fiberPer100g
            existing.sugarPer100g = item.sugarPer100g
            existing.sodiumMgPer100g = item.sodiumMgPer100g
            existing.defaultServingGrams = item.defaultServingGrams
            existing.notes = item.notes
            existing.updatedAt = .now
        } else {
            modelContext.insert(item)
        }

        try modelContext.save()
    }

    func recentFoods(limit: Int = 12) throws -> [FoodItem] {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    private func existingCustomFood(named name: String, brand: String?) throws -> FoodItem? {
        let customRaw = FoodSource.custom.rawValue
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.sourceRaw == customRaw && item.name == name
            }
        )
        return try modelContext.fetch(descriptor).first {
            $0.brand == brand
        }
    }

    private func cachedCustomFoods(matching query: String) throws -> [FoodItem] {
        let lowercased = query.lowercased()
        let customRaw = FoodSource.custom.rawValue
        let recipeRaw = FoodSource.recipe.rawValue
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.sourceRaw == customRaw || item.sourceRaw == recipeRaw
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter {
            $0.displayName.lowercased().contains(lowercased)
        }
    }

    private func cachedFoods(
        matching query: String,
        sources: [FoodSource],
        categories: [FoodCategory]? = nil
    ) throws -> [FoodItem] {
        let lowercased = query.lowercased()
        let sourceSet = Set(sources.map(\.rawValue))
        let categorySet = Set((categories ?? []).map(\.rawValue))
        let descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { item in
            guard sourceSet.contains(item.sourceRaw) else { return false }
            guard item.displayName.lowercased().contains(lowercased) else { return false }
            if categorySet.isEmpty {
                return true
            }
            return categorySet.contains(item.categoryRaw)
        }
    }

    private func cache(items: [FoodItem]) throws {
        for item in items {
            if let existing = try existingCachedItem(matching: item) {
                existing.name = item.name
                existing.brand = item.brand
                existing.barcode = item.barcode
                existing.source = item.source
                existing.category = item.category
                existing.kcalPer100g = item.kcalPer100g
                existing.proteinPer100g = item.proteinPer100g
                existing.carbsPer100g = item.carbsPer100g
                existing.fatPer100g = item.fatPer100g
                existing.fiberPer100g = item.fiberPer100g
                existing.sugarPer100g = item.sugarPer100g
                existing.sodiumMgPer100g = item.sodiumMgPer100g
                existing.defaultServingGrams = item.defaultServingGrams
                existing.updatedAt = .now
            } else {
                modelContext.insert(item)
            }
        }

        try modelContext.save()
    }

    private func remoteSearchIfNeeded(
        _ enabled: Bool,
        operation: @escaping @Sendable () async throws -> [FoodItem]
    ) async -> Result<[FoodItem], Error> {
        guard enabled else {
            return .success([])
        }

        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }

    private func resolvedRemoteItems(
        from result: Result<[FoodItem], Error>,
        cacheSources: [FoodSource],
        cacheCategories: [FoodCategory],
        fallbackQuery: String,
        failureMessage: String
    ) throws -> [FoodItem] {
        switch result {
        case .success(let items):
            guard !items.isEmpty else {
                return []
            }
            try cache(items: items)
            return items
        case .failure(let error):
            logger.error("\(failureMessage, privacy: .public); using cache: \(String(describing: error), privacy: .public)")
            return try cachedFoods(
                matching: fallbackQuery,
                sources: cacheSources,
                categories: cacheCategories
            )
        }
    }

    private func existingCachedItem(matching item: FoodItem) throws -> FoodItem? {
        if let barcode = item.barcode,
           let existing = try modelContext.fetch(
            FetchDescriptor<FoodItem>(
                predicate: #Predicate { food in
                    food.barcode == barcode
                }
            )
           ).first {
            return existing
        }

        let sourceRaw = item.source.rawValue
        let name = item.name
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { food in
                food.sourceRaw == sourceRaw && food.name == name
            }
        )
        return try modelContext.fetch(descriptor).first(where: { $0.brand == item.brand })
    }

    private func searchIntent(for query: String, preferredCategory: FoodCategory?) -> SearchIntent {
        if let preferredCategory {
            switch preferredCategory {
            case .generic:
                return .generic
            case .packaged:
                return .packaged
            case .recipe:
                return .recipe
            }
        }

        return genericDatabase.containsCommonFoodMatch(query) ? .generic : .mixed
    }

    private func mergeAndRank(
        _ items: [FoodItem],
        query: String,
        preferredCategory: FoodCategory?,
        intent: SearchIntent
    ) -> [FoodItem] {
        var seen = Set<String>()
        return items
            .map { item in
                (
                    item: item,
                    score: searchScore(
                        for: item,
                        query: query,
                        preferredCategory: preferredCategory,
                        intent: intent
                    )
                )
            }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    return lhs.item.displayName < rhs.item.displayName
                }
                return lhs.score > rhs.score
            }
            .compactMap { candidate in
                let key = dedupeKey(for: candidate.item)
                guard seen.insert(key).inserted else { return nil }
                return candidate.item
            }
            .prefix(30)
            .map(\.self)
    }

    private func searchScore(
        for item: FoodItem,
        query: String,
        preferredCategory: FoodCategory?,
        intent: SearchIntent
    ) -> Int {
        let normalizedQuery = normalizedTokens(query)
        let querySet = Set(normalizedQuery)
        let displayTokens = Set(normalizedTokens(item.displayName))
        let nameTokens = Set(normalizedTokens(item.name))
        let compactQuery = normalizedText(query)
        let compactDisplay = normalizedText(item.displayName)
        var score = 0

        let overlap = querySet.intersection(displayTokens)
        score += overlap.count * 24

        if compactDisplay == compactQuery {
            score += 180
        } else if normalizedText(item.name) == compactQuery {
            score += 160
        } else if compactDisplay.contains(compactQuery) {
            score += 90
        }

        if let preferredCategory, item.category == preferredCategory {
            score += 75
        }

        if displayTokens == querySet || nameTokens == querySet {
            score += 40
        }

        if displayTokens.isSuperset(of: querySet), !querySet.isEmpty {
            score += 25
        }

        score += sourceWeight(for: item.source, intent: intent)
        score += nutrientCompletenessScore(for: item)

        if item.barcode != nil {
            score += 8
        }

        if item.brand?.isEmpty == false, intent == .packaged {
            score += 6
        }

        return score
    }

    private func sourceWeight(for source: FoodSource, intent: SearchIntent) -> Int {
        switch intent {
        case .generic:
            switch source {
            case .generic:
                90
            case .usda:
                75
            case .custom:
                65
            case .recipe:
                25
            case .off:
                10
            }
        case .packaged:
            switch source {
            case .off:
                95
            case .usda:
                70
            case .custom:
                35
            case .generic:
                10
            case .recipe:
                10
            }
        case .mixed:
            switch source {
            case .off:
                60
            case .usda:
                58
            case .generic:
                52
            case .custom:
                45
            case .recipe:
                22
            }
        case .recipe:
            switch source {
            case .recipe:
                95
            case .custom:
                70
            case .generic:
                58
            case .usda:
                45
            case .off:
                10
            }
        }
    }

    private func nutrientCompletenessScore(for item: FoodItem) -> Int {
        let values = [
            item.kcalPer100g,
            item.proteinPer100g,
            item.carbsPer100g,
            item.fatPer100g,
            item.fiberPer100g,
            item.sugarPer100g,
            item.sodiumMgPer100g,
        ]
        return values.compactMap { $0 }.count * 3
    }

    private func dedupeKey(for item: FoodItem) -> String {
        "\(item.displayName.lowercased())-\(item.barcode ?? item.source.rawValue)"
    }

    private func normalizedText(_ value: String) -> String {
        normalizedTokens(value).joined(separator: " ")
    }

    private func normalizedTokens(_ value: String) -> [String] {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}

private enum SearchIntent {
    case generic
    case packaged
    case mixed
    case recipe

    var shouldSearchGeneric: Bool {
        switch self {
        case .generic, .mixed, .recipe:
            true
        case .packaged:
            false
        }
    }

    var shouldSearchPackaged: Bool {
        switch self {
        case .packaged, .mixed:
            true
        case .generic, .recipe:
            false
        }
    }
}
