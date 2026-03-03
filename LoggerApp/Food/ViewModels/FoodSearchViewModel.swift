import Foundation

@MainActor
final class FoodSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [FoodItem] = []
    @Published private(set) var recentFoods: [FoodItem] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let repository: FoodRepositoryProtocol

    init(repository: FoodRepositoryProtocol) {
        self.repository = repository
    }

    func loadRecent() {
        do {
            recentFoods = try repository.recentFoods(limit: 12)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            results = try await repository.search(query: trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchBarcode(_ code: String) async {
        isSearching = true
        defer { isSearching = false }

        do {
            results = try await repository.fetchByBarcode(code)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

