import Foundation

struct AIInsightsResponse: Codable {
    struct Insight: Codable {
        let title: String
        let detail: String
    }

    let insights: [Insight]

    static func decode(from text: String) throws -> AIInsightsResponse {
        let json = extractJSON(from: text)
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AIInsightsResponse.self, from: data)
        return AIInsightsResponse(
            insights: decoded.insights.compactMap { insight in
                let title = insight.title.trimmingCharacters(in: .whitespacesAndNewlines)
                let detail = insight.detail.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !title.isEmpty, !detail.isEmpty else { return nil }
                return Insight(title: title, detail: detail)
            }
        )
    }

    private static func extractJSON(from text: String) -> String {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return text
        }
        return String(text[start...end])
    }
}
