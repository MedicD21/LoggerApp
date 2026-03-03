import Foundation

struct AIRepository: AIRepositoryProtocol {
    private let client: AnthropicClient

    init(client: AnthropicClient) {
        self.client = client
    }

    func analyzePhoto(_ imageData: Data) async throws -> AIFoodResponse {
        try await client.analyzePhoto(imageData)
    }

    func parseLogText(_ text: String) async throws -> AIFoodResponse {
        try await client.parseFoods(from: text)
    }

    func decomposeRecipe(_ text: String) async throws -> AIFoodResponse {
        try await client.decomposeRecipe(from: text)
    }
}
