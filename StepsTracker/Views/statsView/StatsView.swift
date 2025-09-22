import SwiftUI
import Charts

struct StatsView: View {
    // MARK: - Properties
    @EnvironmentObject var stepModel: StepModel
    @State private var selectedDay: String? = nil
    @State private var selectedSteps: Int = 0
    @State private var glowPulse: Bool = false
    @State private var typingSteps: Int = 0
    @State private var scanningPosition: CGFloat = -200
    
    // MARK: - Views
    var body: some View {
        VStack {
            StatsHeader()
            
            InteractiveChart(
                weeklySteps: stepModel.weeklySteps,
                selectedDay: $selectedDay,
                selectedSteps: $selectedSteps,
                glowPulse: $glowPulse,
                typingSteps: $typingSteps,
                scanningPosition: $scanningPosition
            )
            
            if let selectedDay = selectedDay {
                SelectionCard(
                    selectedDay: selectedDay,
                    selectedSteps: selectedSteps,
                    typingSteps: $typingSteps,
                    glowPulse: $glowPulse,
                    scanningPosition: $scanningPosition
                )
            }
            
            StatsSummary(weeklySteps: stepModel.weeklySteps)
            
            Spacer()
        }
        .background(backgroundGradient)
    }
    
    // MARK: - View Components
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(hex: "101010")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Stats Header Component
struct StatsHeader: View {
    var body: some View {
        Text("Weekly Statistics".localized)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.top)
    }
}