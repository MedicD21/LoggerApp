import Foundation

@MainActor
final class WeightViewModel: ObservableObject {
    @Published private(set) var entries: [WeightEntry] = []
    @Published private(set) var movingAverage: [(date: Date, value: Double)] = []
    @Published var errorMessage: String?

    private let repository: WeightRepository

    init(repository: WeightRepository) {
        self.repository = repository
    }

    func load() {
        do {
            entries = try repository.fetchWeights(days: 90)
            movingAverage = try repository.sevenDayMovingAverage()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(value: Double, unit: WeightUnit, profile: UserProfile) {
        do {
            try repository.addWeight(value: value, unit: unit, date: .now)
            if let latest = try repository.fetchWeights(days: 1).last {
                Task { await repository.syncToHealthIfEnabled(profile: profile, entry: latest) }
            }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

