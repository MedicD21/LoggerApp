import XCTest
@testable import LoggerApp

final class FoodRepositoryRoutingTests: XCTestCase {
    func testBarcodeAlwaysRoutesToBarcodeLookup() {
        let route = FoodRepository.determineRoute(
            query: "banana",
            barcode: "0123456789012",
            genericDatabase: GenericFoodDatabase(items: MockFoodItems.genericSeeds)
        )
        XCTAssertEqual(route, .barcode)
    }

    func testKnownGenericFoodUsesSeedDatabase() {
        let route = FoodRepository.determineRoute(
            query: "banana",
            barcode: nil,
            genericDatabase: GenericFoodDatabase(items: MockFoodItems.genericSeeds)
        )
        XCTAssertEqual(route, .generic)
    }

    func testPackagedAICandidateUsesPackagedSearch() {
        let route = FoodRepository.determineRoute(
            query: "protein bar",
            barcode: nil,
            aiCategory: .packaged,
            genericDatabase: GenericFoodDatabase(items: MockFoodItems.genericSeeds)
        )
        XCTAssertEqual(route, .packagedSearch)
    }

    func testUnknownSearchFallsBackToPackagedLookup() {
        let route = FoodRepository.determineRoute(
            query: "mystery brand yogurt",
            barcode: nil,
            genericDatabase: GenericFoodDatabase(items: MockFoodItems.genericSeeds)
        )
        XCTAssertEqual(route, .packagedSearch)
    }

    func testGenericSearchHandlesDescriptivePluralQueries() {
        let database = GenericFoodDatabase(items: MockFoodItems.genericSeeds)
        let results = database.search("scrambled eggs")

        XCTAssertEqual(results.first?.name, "Egg")
    }

    func testOFFResponseParserNormalizesServingBasedFallbackNutrition() throws {
        let data = Data(
            """
            {
              "status": 1,
              "product": {
                "code": "0888849000012",
                "product_name": "Chocolate Chip Cookie Dough",
                "brands": "Quest",
                "serving_quantity": 60,
                "serving_size": "1 serving (60 g)",
                "nutrition_data_per": "serving",
                "nutriments": {
                  "energy-kcal": 190,
                  "proteins": 21,
                  "carbohydrates": 4,
                  "fat": 9,
                  "fiber": 12,
                  "sugars": 1,
                  "sodium": 0.22
                }
              }
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(OFFBarcodeResponse.self, from: data)
        let item = try XCTUnwrap(response.product.flatMap(OFFResponseParser.normalize(product:)))

        XCTAssertEqual(try XCTUnwrap(item.kcalPer100g), 316.67, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.proteinPer100g), 35, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.carbsPer100g), 6.67, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.fatPer100g), 15, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.fiberPer100g), 20, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.sugarPer100g), 1.67, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.sodiumMgPer100g), 366.67, accuracy: 0.01)
    }
}
