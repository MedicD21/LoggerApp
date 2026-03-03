import SwiftUI

struct FoodDetailView: View {
    let container: AppContainer
    let food: FoodItem

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FoodDetailViewModel

    init(container: AppContainer, food: FoodItem) {
        self.container = container
        self.food = food
        _viewModel = StateObject(wrappedValue: FoodDetailViewModel(food: food, repository: container.logRepository))
    }

    var body: some View {
        Form {
            Section("Food") {
                LabeledContent("Name", value: food.displayName)
                LabeledContent("Source", value: food.source.rawValue.capitalized)
                LabeledContent("Default serving", value: UnitConverter.displayWeight(food.defaultServingGrams))
            }

            Section("Amount") {
                TextField("Amount", value: $viewModel.amount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $viewModel.unit) {
                    ForEach(PortionUnit.imperialFirstCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                Picker("Meal", selection: $viewModel.meal) {
                    ForEach(MealSlot.allCases) { meal in
                        Text(meal.title).tag(meal)
                    }
                }
                TextField("Optional note", text: $viewModel.note, axis: .vertical)
            }

            Section("Preview") {
                metricRow("Calories", value: viewModel.nutritionPreview.calories, unit: "kcal")
                metricRow("Protein", value: viewModel.nutritionPreview.protein, unit: "g")
                metricRow("Carbs", value: viewModel.nutritionPreview.carbs, unit: "g")
                metricRow("Fat", value: viewModel.nutritionPreview.fat, unit: "g")
                metricRow("Fiber", value: viewModel.nutritionPreview.fiber, unit: "g")
            }

            Section {
                Button("Add to Log") {
                    viewModel.addToLog()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(food.name)
        .sensoryFeedback(.success, trigger: viewModel.didLogSuccessfully)
        .onChange(of: viewModel.didLogSuccessfully) { _, newValue in
            if newValue { dismiss() }
        }
        .alert("Logging Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func metricRow(_ title: String, value: Double, unit: String) -> some View {
        LabeledContent(title, value: "\(Int(value.rounded())) \(unit)")
    }
}
