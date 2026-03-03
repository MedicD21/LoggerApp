import SwiftUI

struct CustomFoodEditorView: View {
    let container: AppContainer

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var category: FoodCategory = .generic
    @State private var calories = 0.0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0
    @State private var fiber = 0.0
    @State private var servingOunces = 3.5
    @State private var notes = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Basics") {
                TextField("Name", text: $name)
                TextField("Brand", text: $brand)
                Picker("Type", selection: $category) {
                    Text("Generic").tag(FoodCategory.generic)
                    Text("Recipe").tag(FoodCategory.recipe)
                }
            }

            Section("Per 3.5 oz") {
                nutrientField("Calories", value: $calories)
                nutrientField("Protein", value: $protein)
                nutrientField("Carbs", value: $carbs)
                nutrientField("Fat", value: $fat)
                nutrientField("Fiber", value: $fiber)
            }

            Section("Serving") {
                TextField("Default serving (oz)", value: $servingOunces, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Notes", text: $notes, axis: .vertical)
            }

            Section {
                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Custom Food")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
        .alert("Save Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func nutrientField(_ title: String, value: Binding<Double>) -> some View {
        TextField(title, value: value, format: .number)
            .keyboardType(.decimalPad)
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "A name is required."
            return
        }

        let item = FoodItem(
            name: name,
            brand: brand.nilIfEmpty,
            source: category == .recipe ? .recipe : .custom,
            category: category,
            kcalPer100g: UnitConverter.per100Grams(fromPerThreePointFiveOunces: calories),
            proteinPer100g: UnitConverter.per100Grams(fromPerThreePointFiveOunces: protein),
            carbsPer100g: UnitConverter.per100Grams(fromPerThreePointFiveOunces: carbs),
            fatPer100g: UnitConverter.per100Grams(fromPerThreePointFiveOunces: fat),
            fiberPer100g: UnitConverter.per100Grams(fromPerThreePointFiveOunces: fiber),
            sugarPer100g: nil,
            sodiumMgPer100g: nil,
            isKcalEstimated: false,
            defaultServingGrams: max(servingOunces * UnitConverter.gramsPerOunce, 1),
            notes: notes.nilIfEmpty
        )

        do {
            try container.foodRepository.upsertCustomFood(item)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
