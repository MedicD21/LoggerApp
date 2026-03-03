import Foundation

@MainActor
final class NLPLogViewModel: ObservableObject {
    @Published var input = ""
    @Published var response: AIFoodResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: AIRepositoryProtocol

    init(repository: AIRepositoryProtocol) {
        self.repository = repository
    }

    func parse() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            response = try await repository.parseLogText(trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

