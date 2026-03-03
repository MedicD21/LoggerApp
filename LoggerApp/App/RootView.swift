import SwiftData
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject var router: NavigationRouter

    @Query(sort: \UserProfile.createdAt)
    private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first, profile.onboardingCompleted {
                TabView(selection: $router.selectedTab) {
                    NavigationStack {
                        HomeView(container: container, profile: profile)
                    }
                    .tabItem {
                        Label("Today", systemImage: "house.fill")
                    }
                    .tag(NavigationRouter.Tab.today)

                    NavigationStack {
                        FoodSearchView(container: container)
                    }
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(NavigationRouter.Tab.search)

                    NavigationStack {
                        WeightTrendView(container: container, profile: profile)
                    }
                    .tabItem {
                        Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(NavigationRouter.Tab.trends)

                    NavigationStack {
                        GLP1TrackerView(container: container, profile: profile)
                    }
                    .tabItem {
                        Label("GLP-1", systemImage: "syringe")
                    }
                    .tag(NavigationRouter.Tab.medication)

                    NavigationStack {
                        SettingsView(container: container, profile: profile)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(NavigationRouter.Tab.settings)
                }
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Color.brandSurface, for: .tabBar)
                .toolbarColorScheme(.dark, for: .tabBar)
                .background(BrandBackdrop())
            } else {
                OnboardingView(container: container)
            }
        }
    }
}
