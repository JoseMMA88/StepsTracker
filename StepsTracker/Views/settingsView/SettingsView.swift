import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    @EnvironmentObject var stepModel: StepModel
    
    // MARK: - Views
    var body: some View {
        NavigationView {
            ZStack {
                // Background view that captures touches
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // El foco del TextField se gestiona dentro de GoalsSectionView
                    }
                
                VStack {
                    Form {
                        GoalsSectionView()
                            .environmentObject(stepModel)
                        
                        InformationSectionView()
                        
                        PrivacySectionView()
                        
                        AboutSectionView()
                    }
                }
                .navigationTitle("Settings".localized)
                .background(Color(hex: "101010"))
            }
        }
        .preferredColorScheme(.dark)
    }
}
