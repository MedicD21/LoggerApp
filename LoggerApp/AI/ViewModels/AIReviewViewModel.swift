import Foundation

@MainActor
final class AIReviewViewModel: ObservableObject {
    struct ResolvedCandidate: Identifiable {
        let id = UUID()
        let candidate: AIFoodResponse.Item
        let grams: Double
        var match: FoodItem?
    }

    @Published private(set) var candidates: [ResolvedCandidate] = []
    @Published var meal: MealSlot = .breakfast
    @Published var isResolving = false
    @Published var isConfirming = false
    @Published var didConfirm = false
    @Published var errorMessage: String?

    private let response: AIFoodResponse
    private let foodRepository: FoodRepositoryProtocol
    private let logRepository: LogRepositoryProtocol

    init(
        response: AIFoodResponse,
        foodRepository: FoodRepositoryProtocol,
        logRepository: LogRepositoryProtocol
    ) {
        self.response = response
        self.foodRepository = foodRepository
        self.logRepository = logRepository
    }

    var needsManualReview: Bool {
        response.needsUserConfirmation || candidates.contains(where: { $0.match == nil })
    }

    func resolveMatches() async {
        isResolving = true
        defer { isResolving = false }

        do {
            var resolved: [ResolvedCandidate] = []
            for item in response.items {
                let results = try await foodRepository.search(query: item.name)
                let preferred = preferredMatch(for: item, from: results)
                resolved.append(
                    ResolvedCandidate(
                        candidate: item,
                        grams: UnitConverter.grams(
                            amount: item.estimatedPortion.amount,
                            unit: item.estimatedPortion.unit,
                            defaultServingGrams: preferred?.defaultServingGrams ?? results.first?.defaultServingGrams ?? 100
                        ),
                        match: preferred ?? results.first
                    )
                )
            }
            candidates = resolved
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirm() async {
        guard candidates.allSatisfy({ $0.match != nil }) else {
            errorMessage = "One or more items still need a confirmed database match."
            return
        }

        isConfirming = true
        defer { isConfirming = false }

        do {
            for candidate in candidates {
                guard let match = candidate.match else { continue }
                try logRepository.add(
                    food: match,
                    grams: candidate.grams,
                    meal: meal,
                    note: "AI confirmed"
                )
            }
            didConfirm = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func preferredMatch(for item: AIFoodResponse.Item, from results: [FoodItem]) -> FoodItem? {
        switch item.category {
        case .generic:
            return results.first(where: { $0.source == .generic || $0.source == .custom || $0.source == .recipe })
        case .packaged:
            return results.first(where: { $0.source == .off }) ?? results.first
        case .recipe:
            return results.first(where: { $0.source == .recipe || $0.source == .custom }) ?? results.first
        }
    }
}
