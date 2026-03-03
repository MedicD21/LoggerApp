import XCTest
@testable import LoggerApp

final class MacroCalculatorTests: XCTestCase {
    func testBMRUsesMifflinStJeor() {
        let bmr = NutritionMath.bmr(weightKg: 82, heightCm: 178, ageYears: 35, sex: .male)
        XCTAssertEqual(bmr, 1_762.5, accuracy: 0.1)
    }

    func testTDEEUsesActivityMultiplier() {
        let tdee = NutritionMath.tdee(bmr: 1_760.5, activityLevel: .moderatelyActive)
        XCTAssertEqual(tdee, 2_728.775, accuracy: 0.001)
    }

    func testMacroTargetsApplyCutAdjustment() {
        let targets = NutritionMath.macroTargets(tdee: 2_700, goal: .cut)
        XCTAssertEqual(targets.calories, 2_200, accuracy: 0.01)
        XCTAssertEqual(targets.proteinGrams, 220, accuracy: 0.01)
        XCTAssertEqual(targets.carbGrams, 193, accuracy: 1.0)
        XCTAssertEqual(targets.fatGrams, 61, accuracy: 1.0)
    }
}
