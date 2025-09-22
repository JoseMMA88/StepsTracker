import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct MainView: View {
    // MARK: - Properties
    @EnvironmentObject var stepModel: StepModel
    @State private var showSuccessAnimation = false
    @State private var hasTriggeredGoalAnimation = false

    // Haptics helper
    private let haptics = HapticsHelper()

    // Formatters
    private static let integerFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.groupingSeparator = Locale.current.groupingSeparator
        nf.maximumFractionDigits = 0
        return nf
    }()

    private static let percentFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .percent
        nf.maximumFractionDigits = 0
        return nf
    }()

    private var progressValue: CGFloat {
        let progress = stepModel.progress()
        guard progress.isFinite else { return 0.0 }
        return CGFloat(progress)
    }

    private var percentageText: String {
        let clamped = max(0.0, min(Double(progressValue), 1.0))
        return MainView.percentFormatter.string(from: NSNumber(value: clamped)) ?? "\(Int(clamped * 100))%"
    }

    private var todayStepsText: String {
        let num = NSNumber(value: stepModel.todaySteps)
        return MainView.integerFormatter.string(from: num) ?? "\(stepModel.todaySteps)"
    }

    private var goalStepsText: String {
        let num = NSNumber(value: stepModel.goalSteps)
        return MainView.integerFormatter.string(from: num) ?? "\(stepModel.goalSteps)"
    }

    private var ringColors: [Color] {
        stepModel.todaySteps >= stepModel.goalSteps ? [.green, .green.opacity(0.8)] : [.blue, .purple]
    }

    // MARK: - Views
    var body: some View {
        ZStack {
            BackgroundGradientView()

            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        Spacer()

                        MainProgressSection(
                            width: min(geometry.size.width * 0.85, 350),
                            progressValue: progressValue,
                            ringColors: ringColors,
                            showSuccessAnimation: showSuccessAnimation,
                            todayStepsText: todayStepsText,
                            percentageText: percentageText,
                            reachedGoal: stepModel.todaySteps >= stepModel.goalSteps
                        )
                        .onChange(of: stepModel.todaySteps) { oldValue, newValue in
                            handleStepsChange(newValue: newValue)
                        }

                        DailyGoalView(goalStepsText: goalStepsText,
                                      reachedGoal: stepModel.todaySteps >= stepModel.goalSteps)

                        Spacer()
                    }
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    stepModel.fetchTodaySteps()
                    stepModel.loadWeeklyData()
                }
            }
        }
    }

    // MARK: - Private
    private func handleStepsChange(newValue: Int) {
        // Trigger only once when crossing the goal
        if !hasTriggeredGoalAnimation && newValue >= stepModel.goalSteps {
            hasTriggeredGoalAnimation = true
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showSuccessAnimation = true
            }
            haptics.success()
            // Reset animation after 2 seconds but keep the one-shot flag
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccessAnimation = false
                }
            }
        } else if hasTriggeredGoalAnimation && newValue < stepModel.goalSteps {
            // Allow re-trigger if the user drops below goal (e.g., debugging/reset)
            hasTriggeredGoalAnimation = false
        }
    }
}

// MARK: - Subviews

private struct BackgroundGradientView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(hex: "101010")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct MainProgressSection: View {
    let width: CGFloat
    let progressValue: CGFloat
    let ringColors: [Color]
    let showSuccessAnimation: Bool
    let todayStepsText: String
    let percentageText: String
    let reachedGoal: Bool

    private var innerGlowGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.2), Color.black.opacity(0.05)]),
            center: .center,
            startRadius: 0,
            endRadius: width * 0.4
        )
    }

    var body: some View {
        ZStack {
            ProgressRingView(
                progress: progressValue,
                ringColors: ringColors,
                showSuccessAnimation: showSuccessAnimation
            )

            Circle()
                .fill(innerGlowGradient)
                .padding(30)

            StepCounterView(todayStepsText: todayStepsText,
                            percentageText: percentageText,
                            reachedGoal: reachedGoal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Steps progress".localized)
            .accessibilityValue("\(todayStepsText) " + "steps".localized + ", " + percentageText)
        }
        .frame(width: width)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily steps progress".localized)
        .accessibilityValue(percentageText)
        .accessibilityHint("Shows your progress towards the daily goal".localized)
    }
}

private struct ProgressRingView: View {
    let progress: CGFloat
    let ringColors: [Color]
    let showSuccessAnimation: Bool

    var body: some View {
        ZStack {
            // Base ring
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 20
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: ringColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)

            // Success pulse
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
        }
    }
}





// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStepModel = StepModel()
        mockStepModel.todaySteps = 8_888
        mockStepModel.goalSteps = 10_000

        return MainView()
            .environmentObject(mockStepModel)
            .preferredColorScheme(.dark)
    }
}
