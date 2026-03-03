import Foundation

@MainActor
protocol FoodRepositoryProtocol {
    func search(query: String) async throws -> [FoodItem]
    func fetchByBarcode(_ barcode: String) async throws -> [FoodItem]
    func upsertCustomFood(_ item: FoodItem) throws
    func recentFoods(limit: Int) throws -> [FoodItem]
}

@MainActor
protocol LogRepositoryProtocol {
    func summary(for date: Date, profile: UserProfile) throws -> DailyNutritionSummary
    func add(food: FoodItem, grams: Double, meal: MealSlot, note: String?) throws
    func entries(for date: Date) throws -> [LoggedFood]
}

@MainActor
protocol WeightRepositoryProtocol {
    func addWeight(value: Double, unit: WeightUnit, date: Date) throws
    func fetchWeights(days: Int) throws -> [WeightEntry]
    func sevenDayMovingAverage() throws -> [(date: Date, value: Double)]
}

@MainActor
protocol MedicationRepositoryProtocol {
    func currentSchedule() throws -> MedicationSchedule?
    func saveSchedule(_ schedule: MedicationSchedule) throws
    func logDose(site: String, sideEffects: String?) throws
    func recentDoses(limit: Int) throws -> [MedicationDose]
}

protocol AIRepositoryProtocol {
    func analyzePhoto(_ imageData: Data) async throws -> AIFoodResponse
    func parseLogText(_ text: String) async throws -> AIFoodResponse
    func decomposeRecipe(_ text: String) async throws -> AIFoodResponse
}

