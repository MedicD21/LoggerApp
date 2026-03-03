import XCTest
@testable import LoggerApp

final class NutritionMathTests: XCTestCase {
    func testScaleUsesPerHundredGramMath() {
        let scaled = NutritionMath.scale(nutrient: 25, per100g: 100, amountGrams: 150)
        XCTAssertEqual(scaled, 37.5, accuracy: 0.001)
    }

    func testComputedCaloriesUseMacroFallback() {
        let calories = NutritionMath.computedKcal(protein: 20, carbs: 30, fat: 10)
        XCTAssertEqual(calories, 290, accuracy: 0.001)
    }

    func testMovingAverageBuildsRollingWindow() {
        let points = [
            (date: Date(timeIntervalSince1970: 1), value: 200.0),
            (date: Date(timeIntervalSince1970: 2), value: 198.0),
            (date: Date(timeIntervalSince1970: 3), value: 196.0),
        ]

        let averages = NutritionMath.movingAverage(values: points, window: 2)
        XCTAssertEqual(averages.count, 3)
        XCTAssertEqual(averages[1].value, 199.0, accuracy: 0.001)
        XCTAssertEqual(averages[2].value, 197.0, accuracy: 0.001)
    }
}

