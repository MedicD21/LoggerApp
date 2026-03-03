import Foundation
import OSLog

struct AnthropicClient: Sendable {
    private enum Constants {
        // Model identifier verified against Anthropic's current official model list.
        static let model = "claude-opus-4-6"
        static let version = "2023-06-01"
        static let endpoint = "https://api.anthropic.com/v1/messages"
        static let apiKeyKeychainKey = "anthropic_api_key"
    }

    private let logger = Logger(subsystem: "LoggerApp", category: "AnthropicClient")
    private let session: URLSession
    private let keychain: KeychainService
    private let decoder = JSONDecoder()

    init(session: URLSession = .shared, keychain: KeychainService) {
        self.session = session
        self.keychain = keychain
    }

    func analyzePhoto(_ imageData: Data) async throws -> AIFoodResponse {
        let content: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": imageData.base64EncodedString(),
                ],
            ],
            [
                "type": "text",
                "text": basePrompt(task: "Identify foods in this image."),
            ],
        ]

        return try await send(content: content)
    }

    func parseFoods(from text: String) async throws -> AIFoodResponse {
        try await send(content: [[
            "type": "text",
            "text": "\(basePrompt(task: "Parse this food log into structured food items.")) Input: \(text)",
        ]])
    }

    func decomposeRecipe(from text: String) async throws -> AIFoodResponse {
        try await send(content: [[
            "type": "text",
            "text": "\(basePrompt(task: "Break this recipe into ingredient-level food items.")) Input: \(text)",
        ]])
    }

    private func send(content: [[String: Any]]) async throws -> AIFoodResponse {
        guard let apiKey = keychain.string(for: Constants.apiKeyKeychainKey), !apiKey.isEmpty else {
            throw AppError.missingAPIKey
        }

        guard let url = URL(string: Constants.endpoint) else {
            throw AppError.networkUnavailable
        }

        let payload: [String: Any] = [
            "model": Constants.model,
            "max_tokens": 1024,
            "temperature": 0,
            "messages": [[
                "role": "user",
                "content": content,
            ]],
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Constants.version, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            logger.error("Anthropic request failed.")
            throw AppError.networkUnavailable
        }

        let message = try decoder.decode(AnthropicMessageResponse.self, from: data)
        let text = message.content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")

        do {
            return try AIFoodResponse.decode(from: text)
        } catch {
            logger.error("Malformed Anthropic JSON: \(text, privacy: .public)")
            throw AppError.malformedResponse
        }
    }

    private func basePrompt(task: String) -> String {
        """
        \(task)
        Return JSON only. No prose. No markdown. No commentary. No medical advice.
        If confidence is under 0.75, keep it low and set needs_user_confirmation to true.
        Never fabricate micronutrients. Never fabricate brand nutrition.
        Use this exact schema:
        {
          "items": [
            {
              "name": "string",
              "category": "generic|packaged|recipe",
              "estimated_portion": {
                "amount": 0,
                "unit": "g|oz|cup|tbsp|piece|ml"
              },
              "confidence": 0.0,
              "notes": "string"
            }
          ],
          "assumptions": ["string"],
          "needs_user_confirmation": true
        }
        """
    }

    func saveAPIKey(_ key: String) throws {
        try keychain.set(key, for: Constants.apiKeyKeychainKey)
    }

    func removeAPIKey() {
        keychain.delete(Constants.apiKeyKeychainKey)
    }

    func hasAPIKey() -> Bool {
        keychain.string(for: Constants.apiKeyKeychainKey)?.isEmpty == false
    }
}

private struct AnthropicMessageResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    let content: [ContentBlock]
}
