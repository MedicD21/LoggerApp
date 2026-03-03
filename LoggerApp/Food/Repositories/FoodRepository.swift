import Foundation
import OSLog
import SwiftData

@MainActor
final class FoodRepository: FoodRepositoryProtocol {
    private let logger = Logger(subsystem: "LoggerApp", category: "FoodRepository")
    private let modelContext: ModelContext
    private let genericDatabase: GenericFoodDatabase
    private let offClient: OFFClient

    init(
        modelContext: ModelContext,
        genericDatabase: GenericFoodDatabase,
        offClient: OFFClient
    ) {
        self.modelContext = modelContext
        self.genericDatabase = genericDatabase
        self.offClient = offClient
    }

    static func determineRoute(
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

    func search(query: String) async throws -> [FoodItem] {
        let custom = try cachedCustomFoods(matching: query)
        let route = Self.determineRoute(query: query, barcode: nil, genericDatabase: genericDatabase)

        switch route {
        case .generic:
            return merge(custom, genericDatabase.search(query))
        case .packagedSearch:
            do {
                let items = try await offClient.searchByName(query)
                try cache(items: items)
                return merge(custom, items)
            } catch {
                logger.error("OFF search failed; using cache: \(String(describing: error), privacy: .public)")
                return merge(custom, try cachedPackagedFoods(matching: query))
            }
        case .custom:
            return custom
        case .barcode:
            return []
        }
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
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.sourceRaw == FoodSource.custom.rawValue && item.name == name
            }
        )
        return try modelContext.fetch(descriptor).first {
            $0.brand == brand
        }
    }

    private func cachedCustomFoods(matching query: String) throws -> [FoodItem] {
        let lowercased = query.lowercased()
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.sourceRaw == FoodSource.custom.rawValue || item.sourceRaw == FoodSource.recipe.rawValue
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter {
            $0.displayName.lowercased().contains(lowercased)
        }
    }

    private func cachedPackagedFoods(matching query: String) throws -> [FoodItem] {
        let lowercased = query.lowercased()
        let descriptor = FetchDescriptor<FoodItem>(
            predicate: #Predicate { item in
                item.sourceRaw == FoodSource.off.rawValue
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter {
            $0.displayName.lowercased().contains(lowercased)
        }
    }

    private func cache(items: [FoodItem]) throws {
        for item in items {
            if let barcode = item.barcode,
               let existing = try modelContext.fetch(
                FetchDescriptor<FoodItem>(
                    predicate: #Predicate { food in
                        food.barcode == barcode
                    }
                )
               ).first {
                existing.name = item.name
                existing.brand = item.brand
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

    private func merge(_ lhs: [FoodItem], _ rhs: [FoodItem]) -> [FoodItem] {
        var seen = Set<String>()
        return (lhs + rhs).filter { item in
            let key = "\(item.displayName.lowercased())-\(item.barcode ?? "none")"
            return seen.insert(key).inserted
        }
    }
}

