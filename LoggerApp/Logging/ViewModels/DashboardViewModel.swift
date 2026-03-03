import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var summary: DailyNutritionSummary?
    @Published private(set) var insights: [WeeklyInsight] = []
    @Published var errorMessage: String?

    private let repository: LogRepositoryProtocol

    init(repository: LogRepositoryProtocol) {
        self.repository = repository
    }

    func load(profile: UserProfile) {
        do {
            let summary = try repository.summary(for: .now, profile: profile)
            self.summary = summary
            insights = buildInsights(from: summary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func buildInsights(from summary: DailyNutritionSummary) -> [WeeklyInsight] {
        var output: [WeeklyInsight] = []
        let targets = summary.targets
        let total = summary.total

        if total.protein < targets.proteinGrams * 0.6 {
            output.append(WeeklyInsight(
                title: "Protein is lagging",
                detail: "You are at \(Int(total.protein))g against a \(Int(targets.proteinGrams))g target."
            ))
        }

        if total.calories > targets.calories {
            output.append(WeeklyInsight(
                title: "Calories are over target",
                detail: "You are \(Int(total.calories - targets.calories)) kcal above today’s target."
            ))
        } else if total.calories < targets.calories * 0.55 {
            output.append(WeeklyInsight(
                title: "Logging looks incomplete",
                detail: "Today is far below target. This often means a meal has not been logged yet."
            ))
        }

        if summary.weeklyAverageCalories > targets.calories * 1.1 {
            output.append(WeeklyInsight(
                title: "Weekly average is trending high",
                detail: "Your 7-day average is \(Int(summary.weeklyAverageCalories)) kcal."
            ))
        }

        return output
    }
}

