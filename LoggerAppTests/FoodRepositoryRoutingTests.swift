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
}

