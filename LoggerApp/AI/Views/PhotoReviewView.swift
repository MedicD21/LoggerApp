import SwiftUI

struct PhotoReviewView: View {
    let container: AppContainer
    let response: AIFoodResponse

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AIReviewViewModel

    init(container: AppContainer, response: AIFoodResponse) {
        self.container = container
        self.response = response
        _viewModel = StateObject(
            wrappedValue: AIReviewViewModel(
                response: response,
                foodRepository: container.foodRepository,
                logRepository: container.logRepository
            )
        )
    }

    var body: some View {
        List {
            Section("Assumptions") {
                if response.assumptions.isEmpty {
                    Text("No extra assumptions were reported.")
                } else {
                    ForEach(response.assumptions, id: \.self) { assumption in
                        Text(assumption)
                    }
                }
            }

            Section("Meal") {
                Picker("Meal", selection: $viewModel.meal) {
                    ForEach(MealSlot.allCases) { meal in
                        Text(meal.title).tag(meal)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(viewModel.needsManualReview ? "Manual Review Required" : "Ready to Confirm") {
                if viewModel.isResolving {
                    ProgressView("Matching foods…")
                } else {
                    ForEach(viewModel.candidates) { candidate in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(candidate.candidate.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Int(candidate.candidate.confidence * 100))%")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(candidate.candidate.confidence >= 0.75 ? .green : .orange)
                            }

                            Text(candidate.match?.displayName ?? "Needs a manual database match in Search.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Text("\(UnitConverter.displayWeight(candidate.grams)) • \(candidate.candidate.category.rawValue.capitalized)")
                                if let match = candidate.match {
                                    Text(match.source.title)
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let nutrition = candidate.nutrition {
                                Text(
                                    "\(Int(nutrition.calories.rounded())) kcal • P \(nutrition.protein.decimalString())g • C \(nutrition.carbs.decimalString())g • F \(nutrition.fat.decimalString())g"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            if !candidate.candidate.notes.isEmpty {
                                Text(candidate.candidate.notes)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            Section {
                Button("Confirm and Log") {
                    Task { await viewModel.confirm() }
                }
                .disabled(viewModel.isResolving || viewModel.isConfirming || viewModel.candidates.isEmpty)
                .buttonStyle(.borderedProminent)
            } footer: {
                Text("Low-confidence AI output is never auto-logged. Review every item before confirming.")
            }
        }
        .navigationTitle("Review Items")
        .task { await viewModel.resolveMatches() }
        .onChange(of: viewModel.didConfirm) { _, didConfirm in
            if didConfirm { dismiss() }
        }
        .alert("Review Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
