import SwiftUI

struct HomeView: View {
    let container: AppContainer
    let profile: UserProfile

    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedMeal: MealSlot = .breakfast

    init(container: AppContainer, profile: UserProfile) {
        self.container = container
        self.profile = profile
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                repository: container.logRepository,
                aiRepository: container.aiRepository
            )
        )
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
        .background(BrandBackdrop())
        .navigationTitle("Today")
        .task { await viewModel.load(profile: profile) }
        .refreshable { await viewModel.load(profile: profile) }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandMarkView(size: 56)
            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandMuted)

            Text("Calories remaining")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.brandInk)

            let remaining = max(0, Int((viewModel.summary?.targets.calories ?? 0) - (viewModel.summary?.total.calories ?? 0)))

            Text("\(remaining)")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.brandInk)

            HStack(spacing: 10) {
                Label("Target \(Int((viewModel.summary?.targets.calories ?? 0).rounded())) kcal", systemImage: "target")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.06)))

                Text("Local-first")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.brandMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .brandHeroPanel(accent: .brandSecondary)
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
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandInk)

            if viewModel.insights.isEmpty {
                Text("No issues flagged yet. Logging consistency improves the guidance.")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandMuted)
            } else {
                ForEach(viewModel.insights) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(insight.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.brandInk)
                            Spacer()
                            Text(insight.source == .ai ? "AI" : "Local")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(insight.source == .ai ? Color.brandSecondary : Color.brandMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.05)))
                        }
                        Text(insight.detail)
                            .font(.footnote)
                            .foregroundStyle(Color.brandMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .brandPanel(cornerRadius: 20)
                }
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meals")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.brandInk)

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
                    .foregroundStyle(Color.brandMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(entries, id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.foodItem?.displayName ?? "Unknown Food")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.brandInk)
                            Text(UnitConverter.displayWeight(entry.amountGrams))
                                .font(.caption)
                                .foregroundStyle(Color.brandMuted)
                        }
                        Spacer()
                        Text("\(Int(entry.nutrition.calories.rounded())) kcal")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.brandInk)
                    }
                    .padding(16)
                    .brandPanel(cornerRadius: 18)
                }
            }
        }
    }
}
