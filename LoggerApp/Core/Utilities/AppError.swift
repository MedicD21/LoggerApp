import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case malformedResponse
    case missingAPIKey
    case notificationsDenied
    case cameraUnavailable
    case dataStoreFailure
    case featureDisabled(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            "A network connection is required for this action."
        case .malformedResponse:
            "The server response could not be decoded safely."
        case .missingAPIKey:
            "Add your Anthropic API key in Settings before using AI features."
        case .notificationsDenied:
            "Notification permission is off. Update it in Settings to enable reminders."
        case .cameraUnavailable:
            "The camera is unavailable on this device."
        case .dataStoreFailure:
            "The local store could not be opened."
        case .featureDisabled(let name):
            "\(name) is disabled in your current settings."
        }
    }
}

