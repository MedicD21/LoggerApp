import XCTest
@testable import LoggerApp

final class AIDecodingTests: XCTestCase {
    func testStrictJSONDecodesFixture() throws {
        let data = try fixture(named: "MockAIResponses")
        let text = String(decoding: data, as: UTF8.self)
        let response = try AIFoodResponse.decode(from: text)

        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.items.first?.name, "Egg")
        XCTAssertTrue(response.needsUserConfirmation)
    }

    func testLowConfidenceForcesConfirmation() throws {
        let response = try AIFoodResponse.decode(from: """
        {
          "items": [
            {
              "name": "Toast",
              "category": "generic",
              "estimated_portion": { "amount": 2, "unit": "piece" },
              "confidence": 0.42,
              "notes": "Estimated from text"
            }
          ],
          "assumptions": [],
          "needs_user_confirmation": false
        }
        """)

        XCTAssertTrue(response.needsUserConfirmation)
    }

    func testSanitizationTrimsNamesAndClampsValues() throws {
        let response = try AIFoodResponse.decode(from: """
        {
          "items": [
            {
              "name": "  Greek Yogurt  ",
              "category": "packaged",
              "estimated_portion": { "amount": 0, "unit": "oz" },
              "confidence": 1.4,
              "notes": "  Branded cup  "
            }
          ],
          "assumptions": ["  single serve cup  "],
          "needs_user_confirmation": false
        }
        """)

        XCTAssertEqual(response.items.first?.name, "Greek Yogurt")
        XCTAssertEqual(response.items.first?.estimatedPortion.amount, 0.25)
        XCTAssertEqual(response.items.first?.confidence, 1)
        XCTAssertEqual(response.items.first?.notes, "Branded cup")
        XCTAssertEqual(response.assumptions, ["single serve cup"])
    }

    private func fixture(named name: String) throws -> Data {
        let bundle = Bundle(for: Self.self)
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json"))
        return try Data(contentsOf: url)
    }
}
