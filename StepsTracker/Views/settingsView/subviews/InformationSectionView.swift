import SwiftUI

struct InformationSectionView: View {
    var body: some View {
        Section(header: Text("Information".localized).foregroundColor(.blue)) {
            HStack {
                Text("Version".localized)
                Spacer()
                Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-")
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("Device".localized)
                Spacer()
                Text(UIDevice.current.model)
                    .foregroundColor(.gray)
            }
        }
    }
}
