import Foundation
import OSLog

struct AnthropicClient: Sendable {
    private enum Constants {
        // Snapshot model identifier verified against Anthropic's current official model list.
        static let model = "claude-opus-4-1-20250805"
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
                "text": "Identify the foods and beverages visible in this image.",
            ],
        ]

        return try await sendFoodRequest(content: content)
    }

    func parseFoods(from text: String) async throws -> AIFoodResponse {
        try await sendFoodRequest(content: [[
            "type": "text",
            "text": "Parse this food log into structured food items:\n\(text)",
        ]])
    }

    func decomposeRecipe(from text: String) async throws -> AIFoodResponse {
        try await sendFoodRequest(content: [[
            "type": "text",
            "text": "Break this recipe into ingredient-level food items:\n\(text)",
        ]])
    }

    func generateInsights(context: AIInsightContext) async throws -> [WeeklyInsight] {
        let prompt = """
        Build up to 3 concise nutrition findings for the user's current day and recent trend.
        Focus on logging completeness, calorie trend, protein adequacy, and actionable macro drift.
        Avoid medical advice. Do not mention GLP-1 guidance.
        Return JSON only using this exact schema:
        {
          "insights": [
            {
              "title": "string",
              "detail": "string"
            }
          ]
        }
        Input:
        \(insightPayload(context: context))
        """

        let text = try await send(
            systemPrompt: insightSystemPrompt,
            content: [[
                "type": "text",
                "text": prompt,
            ]]
        )

        do {
            return try AIInsightsResponse.decode(from: text).insights.map {
                WeeklyInsight(title: $0.title, detail: $0.detail, source: .ai)
            }
        } catch {
            logger.error("Malformed Anthropic insights JSON: \(text, privacy: .public)")
            throw AppError.malformedResponse
        }
    }

    private func sendFoodRequest(content: [[String: Any]]) async throws -> AIFoodResponse {
        let text = try await send(systemPrompt: foodSystemPrompt, content: content)

        do {
            return try AIFoodResponse.decode(from: text)
        } catch {
            logger.error("Malformed Anthropic JSON: \(text, privacy: .public)")
            throw AppError.malformedResponse
        }
    }

    private func send(
        systemPrompt: String,
        content: [[String: Any]]
    ) async throws -> String {
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
            "system": systemPrompt,
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
        return message.content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
    }

    private var foodSystemPrompt: String {
        """
        You are a nutrition logging parser for a privacy-first iOS app.
        Return JSON only. No prose. No markdown. No commentary. No medical advice.
        Prefer imperial-friendly units where possible: oz, cup, tbsp, and piece. Use grams only when precision requires it.
        If confidence is under 0.75, keep it low and set needs_user_confirmation to true.
        Never fabricate micronutrients. Never fabricate brand nutrition.
        For packaged foods, prefer the visible package/brand name exactly as shown when identifiable.
        For mixed dishes, split obvious components into separate items when that improves logging accuracy.
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

    private var insightSystemPrompt: String {
        """
        You are a nutrition trend summarizer for a privacy-first iOS app.
        Return JSON only. No prose. No markdown. No medical advice.
        Keep findings factual, concise, and directly grounded in the provided nutrition data.
        """
    }

    private func insightPayload(context: AIInsightContext) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(context),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }

        return string
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
