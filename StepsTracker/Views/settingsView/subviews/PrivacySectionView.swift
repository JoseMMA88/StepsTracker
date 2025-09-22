import SwiftUI

struct PrivacySectionView: View {
    var body: some View {
        Section(header: Text("Privacy".localized).foregroundColor(.blue)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Data Privacy".localized)
                    .font(.headline)
                
                Text("Your step data is stored locally on your device and is never shared with third parties. We only use this data to provide you with accurate step tracking and statistics.".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            
            Button(action: {
                if let url = URL(string: "https://josemma88.github.io/stepstracker-privacy/") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack {
                    Text("Privacy Policy".localized)
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}
