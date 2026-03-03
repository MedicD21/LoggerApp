import Foundation

struct AIFoodResponse: Codable, Hashable {
    struct FoodItemPortion: Codable, Hashable {
        let amount: Double
        let unit: PortionUnit
    }

    struct Item: Codable, Hashable, Identifiable {
        let name: String
        let category: FoodCategory
        let estimatedPortion: FoodItemPortion
        let confidence: Double
        let notes: String

        var id: String { "\(name)-\(estimatedPortion.amount)-\(estimatedPortion.unit.rawValue)" }

        enum CodingKeys: String, CodingKey {
            case name
            case category
            case estimatedPortion = "estimated_portion"
            case confidence
            case notes
        }
    }

    let items: [Item]
    let assumptions: [String]
    var needsUserConfirmation: Bool

    enum CodingKeys: String, CodingKey {
        case items
        case assumptions
        case needsUserConfirmation = "needs_user_confirmation"
    }

    static func decode(from text: String) throws -> AIFoodResponse {
        let json = extractJSON(from: text)
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AIFoodResponse.self, from: data)
        let needsReview = decoded.items.contains { $0.confidence < 0.75 }
        return AIFoodResponse(
            items: decoded.items,
            assumptions: decoded.assumptions,
            needsUserConfirmation: decoded.needsUserConfirmation || needsReview
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

