import SwiftUI

@main
struct LoggerAppApp: App {
    @StateObject private var container = AppContainer()
    @StateObject private var router = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            RootView(container: container, router: router)
                .modelContainer(container.modelContainer)
                .tint(.brandPrimary)
                .preferredColorScheme(.dark)
                .fontDesign(.rounded)
        }
    }
}
