import Foundation
import OSLog

struct USDAClient: Sendable {
    private enum Constants {
        static let endpoint = "https://api.nal.usda.gov/fdc/v1/foods/search"
        static let apiKeyKeychainKey = "usda_api_key"
        static let fallbackAPIKey = "DEMO_KEY"
    }

    private let logger = Logger(subsystem: "LoggerApp", category: "USDAClient")
    private let session: URLSession
    private let keychain: KeychainService
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared, keychain: KeychainService) {
        self.session = session
        self.keychain = keychain
    }

    func searchGenericFoods(_ query: String, limit: Int = 12) async throws -> [FoodItem] {
        try await search(query: query, types: [.foundation, .srLegacy, .survey], limit: limit)
    }

    func searchPackagedFoods(_ query: String, limit: Int = 12) async throws -> [FoodItem] {
        try await search(query: query, types: [.branded], limit: limit)
    }

    func saveAPIKey(_ key: String) throws {
        try keychain.set(key, for: Constants.apiKeyKeychainKey)
    }

    func removeAPIKey() {
        keychain.delete(Constants.apiKeyKeychainKey)
    }

    func hasCustomAPIKey() -> Bool {
        keychain.string(for: Constants.apiKeyKeychainKey)?.isEmpty == false
    }

    func usingFallbackAPIKey() -> Bool {
        !hasCustomAPIKey()
    }

    private func search(
        query: String,
        types: [USDADataType],
        limit: Int
    ) async throws -> [FoodItem] {
        guard var components = URLComponents(string: Constants.endpoint) else {
            throw AppError.networkUnavailable
        }

        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey()),
        ]

        guard let url = components.url else {
            throw AppError.networkUnavailable
        }

        let payload = USDASearchRequest(
            query: query,
            pageSize: min(max(limit, 1), 25),
            dataType: types.map(\.rawValue)
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let decoded = try decoder.decode(USDASearchResponse.self, from: data)
        return decoded.foods.compactMap(USDAResponseParser.normalize(food:))
    }

    private func apiKey() -> String {
        let saved = keychain.string(for: Constants.apiKeyKeychainKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (saved?.isEmpty == false ? saved : nil) ?? Constants.fallbackAPIKey
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }

        guard (200..<300).contains(http.statusCode) else {
            logger.error("USDA request failed with status \(http.statusCode, privacy: .public)")
            throw AppError.networkUnavailable
        }
    }
}

private struct USDASearchRequest: Encodable {
    let query: String
    let pageSize: Int
    let dataType: [String]
    let requireAllWords: Bool = false

    enum CodingKeys: String, CodingKey {
        case query
        case pageSize
        case dataType
        case requireAllWords
    }
}

private enum USDADataType: String {
    case branded = "Branded"
    case foundation = "Foundation"
    case srLegacy = "SR Legacy"
    case survey = "Survey (FNDDS)"
}

struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable {
    let fdcID: Int?
    let description: String?
    let dataType: String?
    let brandOwner: String?
    let gtinUPC: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let foodCategory: String?
    let foodNutrients: [USDAFoodNutrient]

    enum CodingKeys: String, CodingKey {
        case fdcID = "fdcId"
        case description
        case dataType
        case brandOwner
        case gtinUPC = "gtinUpc"
        case servingSize
        case servingSizeUnit
        case householdServingFullText
        case foodCategory
        case foodNutrients
    }
}

struct USDAFoodNutrient: Decodable {
    let nutrientID: Int?
    let nutrientName: String?
    let nutrientNumber: String?
    let unitName: String?
    let value: Double?

    enum CodingKeys: String, CodingKey {
        case nutrientID = "nutrientId"
        case nutrientName
        case nutrientNumber
        case unitName
        case value
    }
}

enum USDAResponseParser {
    static func normalize(food: USDAFood) -> FoodItem? {
        let name = food.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { return nil }

        let protein = nutrientValue(in: food.foodNutrients, ids: [203])
        let carbs = nutrientValue(in: food.foodNutrients, ids: [205])
        let fat = nutrientValue(in: food.foodNutrients, ids: [204])
        let fiber = nutrientValue(in: food.foodNutrients, ids: [291])
        let sugar = nutrientValue(in: food.foodNutrients, ids: [269])
        let sodiumMg = sodiumValue(in: food.foodNutrients)
        let kcal = nutrientValue(in: food.foodNutrients, ids: [1008, 2047])
        let servingGrams = defaultServingGrams(for: food)
        let category = food.category

        return FoodItem(
            name: cleanName(name),
            brand: food.brandOwner?.trimmedNilIfEmpty,
            barcode: food.gtinUPC?.trimmedNilIfEmpty,
            source: .usda,
            category: category,
            kcalPer100g: kcal ?? NutritionMath.computedKcal(
                protein: protein ?? 0,
                carbs: carbs ?? 0,
                fat: fat ?? 0
            ),
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: fiber,
            sugarPer100g: sugar,
            sodiumMgPer100g: sodiumMg,
            isKcalEstimated: kcal == nil,
            defaultServingGrams: servingGrams,
            notes: [food.dataType, food.foodCategory, food.householdServingFullText]
                .compactMap { $0?.trimmedNilIfEmpty }
                .joined(separator: " • ")
                .trimmedNilIfEmpty
        )
    }

    private static func nutrientValue(in nutrients: [USDAFoodNutrient], ids: Set<Int>) -> Double? {
        nutrients
            .first(where: { nutrient in
                if let nutrientID = nutrient.nutrientID {
                    return ids.contains(nutrientID)
                }
                return ids.contains(Int(nutrient.nutrientNumber ?? "") ?? -1)
            })?
            .value
    }

    private static func sodiumValue(in nutrients: [USDAFoodNutrient]) -> Double? {
        guard let nutrient = nutrients.first(where: { nutrient in
            nutrient.nutrientID == 307 || nutrient.nutrientNumber == "307"
        }) else {
            return nil
        }

        guard let value = nutrient.value else { return nil }
        switch nutrient.unitName?.uppercased() {
        case "G":
            return value * 1_000
        default:
            return value
        }
    }

    private static func defaultServingGrams(for food: USDAFood) -> Double {
        if let grams = food.householdServingFullText?.extractGrams(), grams > 0 {
            return grams
        }

        if let servingSize = food.servingSize,
           let unit = food.servingSizeUnit?.uppercased() {
            switch unit {
            case "G", "GM", "GRAM":
                return max(servingSize, 1)
            case "OZ":
                return max(servingSize * UnitConverter.gramsPerOunce, 1)
            case "LB":
                return max(servingSize * UnitConverter.gramsPerPound, 1)
            case "ML":
                return max(servingSize, 1)
            case "TBSP":
                return max(servingSize * 15, 1)
            case "CUP":
                return max(servingSize * 240, 1)
            default:
                break
            }
        }

        return food.category == .packaged ? 30 : 100
    }

    private static func cleanName(_ name: String) -> String {
        name
            .replacingOccurrences(of: ", UPC: .*$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension USDAFood {
    var category: FoodCategory {
        dataType?.caseInsensitiveCompare("Branded") == .orderedSame ? .packaged : .generic
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func extractGrams() -> Double? {
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
