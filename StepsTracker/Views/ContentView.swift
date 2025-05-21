import SwiftUI

struct ContentView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainView()
                .tabItem {
                    Label("Today", systemImage: "figure.walk")
                }
                .tag(0)
            
            StatsView()
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
} 