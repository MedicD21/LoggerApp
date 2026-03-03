import Foundation
import OSLog

struct OFFClient {
    private let logger = Logger(subsystem: "LoggerApp", category: "OFFClient")
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchByBarcode(_ barcode: String) async throws -> [FoodItem] {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=code,product_name,brands,serving_quantity,serving_size,nutrition_data_per,nutriments") else {
            return []
        }

        var request = URLRequest(url: url)
        request.setValue("LoggerApp/1.0 (help@loggerapp.app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let productResponse = try decoder.decode(OFFBarcodeResponse.self, from: data)
        guard productResponse.status == 1,
              let product = productResponse.product,
              let item = OFFResponseParser.normalize(product: product) else {
            return []
        }

        return [item]
    }

    func searchByName(_ query: String) async throws -> [FoodItem] {
        guard var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl") else {
            return []
        }

        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20"),
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_quantity,serving_size,nutrition_data_per,nutriments"),
        ]

        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("LoggerApp/1.0 (help@loggerapp.app)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        try validate(response: response)

        let searchResponse = try decoder.decode(OFFSearchResponse.self, from: data)
        return searchResponse.products.compactMap(OFFResponseParser.normalize(product:))
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw AppError.networkUnavailable
        }

        guard (200..<300).contains(http.statusCode) else {
            logger.error("OFF request failed with status \(http.statusCode, privacy: .public)")
            throw AppError.networkUnavailable
        }
    }
}

struct OFFBarcodeResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingQuantity: Double?
    let servingSize: String?
    let nutritionDataPer: String?
    let nutriments: OFFNutriments

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        self.code = container.decodeFlexibleString(forKey: "code")
        self.productName = container.decodeFlexibleString(forKey: "product_name")
        self.brands = container.decodeFlexibleString(forKey: "brands")
        self.servingQuantity = container.decodeFlexibleDouble(forKey: "serving_quantity")
        self.servingSize = container.decodeFlexibleString(forKey: "serving_size")
        self.nutritionDataPer = container.decodeFlexibleString(forKey: "nutrition_data_per")

        if let nutrimentsKey = DynamicKey(stringValue: "nutriments"),
           let decoded = try? container.decode(OFFNutriments.self, forKey: nutrimentsKey) {
            self.nutriments = decoded
        } else {
            self.nutriments = OFFNutriments()
        }
    }
}

struct OFFNutriments: Decodable {
    let kcal: Double?
    let kcal100g: Double?
    let kcalServing: Double?
    let proteins: Double?
    let proteins100g: Double?
    let proteinsServing: Double?
    let carbohydrates: Double?
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?
    let fat: Double?
    let fat100g: Double?
    let fatServing: Double?
    let fiber: Double?
    let fiber100g: Double?
    let fiberServing: Double?
    let sugars: Double?
    let sugars100g: Double?
    let sugarsServing: Double?
    let sodium: Double?
    let sodium100g: Double?
    let sodiumServing: Double?

    init() {
        self.kcal = nil
        self.kcal100g = nil
        self.kcalServing = nil
        self.proteins = nil
        self.proteins100g = nil
        self.proteinsServing = nil
        self.carbohydrates = nil
        self.carbohydrates100g = nil
        self.carbohydratesServing = nil
        self.fat = nil
        self.fat100g = nil
        self.fatServing = nil
        self.fiber = nil
        self.fiber100g = nil
        self.fiberServing = nil
        self.sugars = nil
        self.sugars100g = nil
        self.sugarsServing = nil
        self.sodium = nil
        self.sodium100g = nil
        self.sodiumServing = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        self.kcal = container.decodeFlexibleDouble(forKey: "energy-kcal")
            ?? container.decodeFlexibleDouble(forKey: "energy-kcal_value")
        self.kcal100g = container.decodeFlexibleDouble(forKey: "energy-kcal_100g")
        self.kcalServing = container.decodeFlexibleDouble(forKey: "energy-kcal_serving")
        self.proteins = container.decodeFlexibleDouble(forKey: "proteins")
            ?? container.decodeFlexibleDouble(forKey: "proteins_value")
        self.proteins100g = container.decodeFlexibleDouble(forKey: "proteins_100g")
        self.proteinsServing = container.decodeFlexibleDouble(forKey: "proteins_serving")
        self.carbohydrates = container.decodeFlexibleDouble(forKey: "carbohydrates")
            ?? container.decodeFlexibleDouble(forKey: "carbohydrates_value")
        self.carbohydrates100g = container.decodeFlexibleDouble(forKey: "carbohydrates_100g")
        self.carbohydratesServing = container.decodeFlexibleDouble(forKey: "carbohydrates_serving")
        self.fat = container.decodeFlexibleDouble(forKey: "fat")
            ?? container.decodeFlexibleDouble(forKey: "fat_value")
        self.fat100g = container.decodeFlexibleDouble(forKey: "fat_100g")
        self.fatServing = container.decodeFlexibleDouble(forKey: "fat_serving")
        self.fiber = container.decodeFlexibleDouble(forKey: "fiber")
            ?? container.decodeFlexibleDouble(forKey: "fiber_value")
        self.fiber100g = container.decodeFlexibleDouble(forKey: "fiber_100g")
        self.fiberServing = container.decodeFlexibleDouble(forKey: "fiber_serving")
        self.sugars = container.decodeFlexibleDouble(forKey: "sugars")
            ?? container.decodeFlexibleDouble(forKey: "sugars_value")
        self.sugars100g = container.decodeFlexibleDouble(forKey: "sugars_100g")
        self.sugarsServing = container.decodeFlexibleDouble(forKey: "sugars_serving")
        self.sodium = container.decodeFlexibleDouble(forKey: "sodium")
            ?? container.decodeFlexibleDouble(forKey: "sodium_value")
        self.sodium100g = container.decodeFlexibleDouble(forKey: "sodium_100g")
        self.sodiumServing = container.decodeFlexibleDouble(forKey: "sodium_serving")
    }
}

private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

private extension KeyedDecodingContainer where Key == DynamicKey {
    func decodeFlexibleDouble(forKey key: String) -> Double? {
        guard let codingKey = DynamicKey(stringValue: key) else { return nil }
        if let value = try? decode(Double.self, forKey: codingKey) {
            return value
        }
        if let value = try? decode(Int.self, forKey: codingKey) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: codingKey) {
            return Double(value)
        }
        return nil
    }

    func decodeFlexibleString(forKey key: String) -> String? {
        guard let codingKey = DynamicKey(stringValue: key) else { return nil }
        if let value = try? decode(String.self, forKey: codingKey) {
            return value
        }
        if let value = try? decode(Double.self, forKey: codingKey) {
            return String(value)
        }
        if let value = try? decode(Int.self, forKey: codingKey) {
            return String(value)
        }
        return nil
    }
}
