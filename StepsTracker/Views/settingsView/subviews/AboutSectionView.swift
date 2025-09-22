import SwiftUI

struct AboutSectionView: View {
    var body: some View {
        Section(header: Text("About".localized).foregroundColor(.blue)) {
            VStack(alignment: .leading, spacing: 10) {
                Text("StepTracker".localized)
                    .font(.headline)
                
                Text("This application uses device sensors to accurately track your steps and help you achieve your daily physical activity goals.".localized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}
