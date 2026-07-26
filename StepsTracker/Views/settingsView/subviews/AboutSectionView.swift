import SwiftUI

struct AboutSectionView: View {
    var body: some View {
        Section("About") {
            LabeledContent("App") {
                Text("StepsTracker")
            }
            Text("A simple, private view of the steps that Health records on your device.")
                .foregroundStyle(.secondary)
        }
    }
}
