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
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=code,product_name,brands,serving_quantity,serving_size,nutriments") else {
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
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_quantity,serving_size,nutriments"),
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
    let nutriments: OFFNutriments

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingQuantity = "serving_quantity"
        case servingSize = "serving_size"
        case nutriments
    }
}

struct OFFNutriments: Decodable {
    let kcal100g: Double?
    let kcalServing: Double?
    let proteins100g: Double?
    let proteinsServing: Double?
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?
    let fat100g: Double?
    let fatServing: Double?
    let fiber100g: Double?
    let sugars100g: Double?
    let sodium100g: Double?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        self.kcal100g = container.decodeFlexibleDouble(forKey: "energy-kcal_100g")
        self.kcalServing = container.decodeFlexibleDouble(forKey: "energy-kcal_serving")
        self.proteins100g = container.decodeFlexibleDouble(forKey: "proteins_100g")
        self.proteinsServing = container.decodeFlexibleDouble(forKey: "proteins_serving")
        self.carbohydrates100g = container.decodeFlexibleDouble(forKey: "carbohydrates_100g")
        self.carbohydratesServing = container.decodeFlexibleDouble(forKey: "carbohydrates_serving")
        self.fat100g = container.decodeFlexibleDouble(forKey: "fat_100g")
        self.fatServing = container.decodeFlexibleDouble(forKey: "fat_serving")
        self.fiber100g = container.decodeFlexibleDouble(forKey: "fiber_100g")
        self.sugars100g = container.decodeFlexibleDouble(forKey: "sugars_100g")
        self.sodium100g = container.decodeFlexibleDouble(forKey: "sodium_100g")
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
}

