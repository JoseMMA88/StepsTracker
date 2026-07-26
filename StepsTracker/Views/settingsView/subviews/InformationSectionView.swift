import SwiftUI

struct InformationSectionView: View {
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    var body: some View {
        Section("Information") {
            LabeledContent("Version", value: version)
        }
    }
}
