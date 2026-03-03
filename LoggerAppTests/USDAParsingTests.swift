import XCTest
@testable import LoggerApp

final class USDAParsingTests: XCTestCase {
    func testGenericUSDAFoodNormalizesToGenericFoodItem() throws {
        let data = Data(
            """
            {
              "foods": [
                {
                  "fdcId": 1102653,
                  "description": "Bananas, raw",
                  "dataType": "Foundation",
                  "servingSize": 118,
                  "servingSizeUnit": "G",
                  "householdServingFullText": "1 medium (118g)",
                  "foodCategory": "Fruits",
                  "foodNutrients": [
                    { "nutrientId": 1008, "nutrientNumber": "208", "unitName": "KCAL", "value": 89 },
                    { "nutrientId": 203, "nutrientNumber": "203", "unitName": "G", "value": 1.09 },
                    { "nutrientId": 205, "nutrientNumber": "205", "unitName": "G", "value": 22.84 },
                    { "nutrientId": 204, "nutrientNumber": "204", "unitName": "G", "value": 0.33 },
                    { "nutrientId": 291, "nutrientNumber": "291", "unitName": "G", "value": 2.6 },
                    { "nutrientId": 269, "nutrientNumber": "269", "unitName": "G", "value": 12.2 },
                    { "nutrientId": 307, "nutrientNumber": "307", "unitName": "MG", "value": 1 }
                  ]
                }
              ]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        let item = try XCTUnwrap(response.foods.first.flatMap(USDAResponseParser.normalize(food:)))

        XCTAssertEqual(item.source, .usda)
        XCTAssertEqual(item.category, .generic)
        XCTAssertEqual(item.name, "Bananas, raw")
        XCTAssertEqual(item.defaultServingGrams, 118, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.kcalPer100g), 89, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.proteinPer100g), 1.09, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.carbsPer100g), 22.84, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.sodiumMgPer100g), 1, accuracy: 0.01)
    }

    func testBrandedUSDAFoodNormalizesToPackagedFoodItem() throws {
        let data = Data(
            """
            {
              "foods": [
                {
                  "fdcId": 2719427,
                  "description": "Chocolate Chip Cookie Dough Protein Bar",
                  "dataType": "Branded",
                  "brandOwner": "Quest Nutrition",
                  "gtinUpc": "888849000012",
                  "servingSize": 60,
                  "servingSizeUnit": "G",
                  "householdServingFullText": "1 bar (60g)",
                  "foodCategory": "Nutrition Bars",
                  "foodNutrients": [
                    { "nutrientId": 1008, "nutrientNumber": "208", "unitName": "KCAL", "value": 316.67 },
                    { "nutrientId": 203, "nutrientNumber": "203", "unitName": "G", "value": 35 },
                    { "nutrientId": 205, "nutrientNumber": "205", "unitName": "G", "value": 6.67 },
                    { "nutrientId": 204, "nutrientNumber": "204", "unitName": "G", "value": 15 },
                    { "nutrientId": 291, "nutrientNumber": "291", "unitName": "G", "value": 20 },
                    { "nutrientId": 269, "nutrientNumber": "269", "unitName": "G", "value": 1.67 },
                    { "nutrientId": 307, "nutrientNumber": "307", "unitName": "MG", "value": 366.67 }
                  ]
                }
              ]
            }
            """.utf8
        )

        let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        let item = try XCTUnwrap(response.foods.first.flatMap(USDAResponseParser.normalize(food:)))

        XCTAssertEqual(item.source, .usda)
        XCTAssertEqual(item.category, .packaged)
        XCTAssertEqual(item.brand, "Quest Nutrition")
        XCTAssertEqual(item.barcode, "888849000012")
        XCTAssertEqual(item.defaultServingGrams, 60, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.kcalPer100g), 316.67, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.proteinPer100g), 35, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(item.sodiumMgPer100g), 366.67, accuracy: 0.01)
    }
}
