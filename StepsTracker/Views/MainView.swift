import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct MainView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var showSuccessAnimation = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "101010")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer()
                        
                        // Main futuristic circle
                        ZStack {
                            // Circular background with gradient
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 20
                                )
                            
                            // Animated circular progress
                            Circle()
                                .trim(from: 0, to: CGFloat(stepModel.progress()))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: stepModel.todaySteps >= stepModel.goalSteps ? [.green, .green.opacity(0.8)] : [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: stepModel.progress())
                                .onChange(of: stepModel.todaySteps) { oldValue, newValue in
                                    if newValue >= stepModel.goalSteps {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                            showSuccessAnimation = true
                                        }
                                        // Reset animation after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                showSuccessAnimation = false
                                            }
                                        }
                                    }
                                }
                            
                            // Success animation
                            if showSuccessAnimation {
                                Circle()
                                    .stroke(Color.green, lineWidth: 2)
                                    .scaleEffect(showSuccessAnimation ? 1.2 : 1.0)
                                    .opacity(showSuccessAnimation ? 0 : 1)
                                    .animation(
                                        .easeInOut(duration: 1)
                                        .repeatCount(2, autoreverses: false),
                                        value: showSuccessAnimation
                                    )
                            }
                            
                            // Inner circle with glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.2), Color.black.opacity(0.05)]),
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: geometry.size.width * 0.4
                                    )
                                )
                                .padding(30)
                            
                            // Step counter with animation
                            VStack(spacing: 10) {
                                Text("\(stepModel.todaySteps)")
                                    .font(.system(size: 70, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: stepModel.todaySteps >= stepModel.goalSteps ? .green.opacity(0.5) : .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                                
                                Text("STEPS")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Text("\(Int(stepModel.progress() * 100))%")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .frame(width: min(geometry.size.width * 0.85, 350))
                        .padding()
                        
                        // Daily goal display
                        HStack {
                            Text("Daily goal:")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text("\(stepModel.goalSteps) steps")
                                .font(.headline)
                                .foregroundColor(stepModel.todaySteps >= stepModel.goalSteps ? .green : .blue)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.1))
                                .shadow(color: stepModel.todaySteps >= stepModel.goalSteps ? .green.opacity(0.2) : .blue.opacity(0.2), radius: 10, x: 0, y: 5)
                        )
                        
                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    // Update data
                    stepModel.fetchTodaySteps()
                    stepModel.loadWeeklyData()
                }
            }
        }
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock StepModel for preview
        let mockStepModel = StepModel()
        mockStepModel.todaySteps = 8888
        mockStepModel.goalSteps = 10000
        
        return MainView()
            .environmentObject(mockStepModel)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
