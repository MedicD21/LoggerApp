import SwiftUI

struct HomeView: View {
    let container: AppContainer
    let profile: UserProfile

    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedMeal: MealSlot = .breakfast

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(wrappedValue: DashboardViewModel(repository: container.logRepository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                ringsSection
                insightsSection
                mealsSection
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.brandBackground, Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Today")
        .task { viewModel.load(profile: profile) }
        .refreshable { viewModel.load(profile: profile) }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("Calories remaining")
                .font(.headline)

            let remaining = max(0, Int((viewModel.summary?.targets.calories ?? 0) - (viewModel.summary?.total.calories ?? 0)))

            Text("\(remaining)")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(Color.brandInk)

            Text("Fast logging, strict confirmations, local-first storage.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.brandSecondary.opacity(0.35), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var ringsSection: some View {
        let summary = viewModel.summary
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                MacroRingView(
                    title: "Calories",
                    consumed: summary?.total.calories ?? 0,
                    target: summary?.targets.calories ?? 1,
                    tint: .brandPrimary
                )
                MacroRingView(
                    title: "Protein",
                    consumed: summary?.total.protein ?? 0,
                    target: summary?.targets.proteinGrams ?? 1,
                    tint: .brandSecondary
                )
                MacroRingView(
                    title: "Carbs",
                    consumed: summary?.total.carbs ?? 0,
                    target: summary?.targets.carbGrams ?? 1,
                    tint: .blue
                )
                MacroRingView(
                    title: "Fat",
                    consumed: summary?.total.fat ?? 0,
                    target: summary?.targets.fatGrams ?? 1,
                    tint: .orange
                )
            }
            .padding(.vertical, 4)
        }
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Alerts")
                .font(.headline)

            if viewModel.insights.isEmpty {
                Text("No issues flagged yet. Logging consistency improves the guidance.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.insights) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.title)
                            .font(.subheadline.weight(.semibold))
                        Text(insight.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.brandCard))
                }
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals")
                .font(.headline)

            Picker("Meal", selection: $selectedMeal) {
                ForEach(MealSlot.allCases) { meal in
                    Text(meal.title).tag(meal)
                }
            }
            .pickerStyle(.segmented)

            let entries = viewModel.summary?.entries.filter { $0.meal == selectedMeal } ?? []
            if entries.isEmpty {
                Text("No entries in \(selectedMeal.title.lowercased()) yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.foodItem?.displayName ?? "Unknown Food")
                                .font(.subheadline.weight(.semibold))
                            Text(UnitConverter.displayWeight(entry.amountGrams))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(Int(entry.nutrition.calories.rounded())) kcal")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.brandCard))
                }
            }
        }
    }
}

