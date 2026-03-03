import Foundation

@MainActor
final class FoodDetailViewModel: ObservableObject {
    @Published var amount: Double
    @Published var unit: PortionUnit = .g
    @Published var meal: MealSlot = .breakfast
    @Published var note = ""
    @Published var didLogSuccessfully = false
    @Published var errorMessage: String?

    let food: FoodItem
    private let repository: LogRepositoryProtocol

    init(food: FoodItem, repository: LogRepositoryProtocol) {
        self.food = food
        self.repository = repository
        self.amount = food.defaultServingGrams
    }

    var grams: Double {
        UnitConverter.grams(amount: amount, unit: unit, defaultServingGrams: food.defaultServingGrams)
    }

    var nutritionPreview: NutritionSnapshot {
        food.nutrition(for: grams)
    }

    func addToLog() {
        do {
            try repository.add(food: food, grams: grams, meal: meal, note: note.nilIfEmpty)
            didLogSuccessfully.toggle()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
