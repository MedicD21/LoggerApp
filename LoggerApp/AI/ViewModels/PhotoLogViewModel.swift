import Foundation

@MainActor
final class PhotoLogViewModel: ObservableObject {
    @Published var response: AIFoodResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository: AIRepositoryProtocol

    init(repository: AIRepositoryProtocol) {
        self.repository = repository
    }

    func analyze(imageData: Data) async {
        isLoading = true
        defer { isLoading = false }

        do {
            response = try await repository.analyzePhoto(imageData)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

