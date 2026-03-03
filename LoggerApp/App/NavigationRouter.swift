import Foundation

@MainActor
final class NavigationRouter: ObservableObject {
    enum Tab: Hashable {
        case today
        case search
        case trends
        case medication
        case settings
    }

    @Published var selectedTab: Tab = .today
}

