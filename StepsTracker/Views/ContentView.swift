import SwiftUI

struct ContentView: View {
    @Environment(StepModel.self) private var stepModel
    @State private var selectedTab = AppTab.today

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView()
                .environment(stepModel)
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }
                .tag(AppTab.today)

            StatsView()
                .environment(stepModel)
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
                .tag(AppTab.statistics)

            SettingsView()
                .environment(stepModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .tint(.accentColor)
    }
}

private enum AppTab: Hashable {
    case today
    case statistics
    case settings
}
