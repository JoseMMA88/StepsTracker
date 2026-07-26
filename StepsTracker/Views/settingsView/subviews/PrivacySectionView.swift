import SwiftUI

struct PrivacySectionView: View {
    var body: some View {
        Section("Privacy") {
            Text("StepsTracker reads your step count from Apple Health to show your progress. Your health data is not shared with third parties.")
                .foregroundStyle(.secondary)

            Link(destination: URL(string: "https://josemma88.github.io/stepstracker-privacy/")!) {
                Label("Privacy policy", systemImage: "hand.raised")
            }
        }
    }
}
