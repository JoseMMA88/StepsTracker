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
    
    // MARK: - Computed Properties
    
    // MARK: - Views
    var body: some View {
        VStack {
            Text("Weekly Statistics".localized)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)
            
            // Weekly chart with futuristic effects
            ZStack {
                Chart {
                    ForEach(stepModel.weeklySteps.sorted(by: { $0.key < $1.key }), id: \.key) { date, steps in
                        createBarMark(for: date, steps: steps)
                    }
                }
                .chartXSelection(value: .constant(selectedDay))
                .chartGesture { chartProxy in
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let location = value.location
                            if let day: String = chartProxy.value(atX: location.x) {
                                // Find the date that corresponds to this day
                                if let selectedDate = stepModel.weeklySteps.keys.first(where: { formatDay($0) == day }) {
                                    let fullDayFormat = formatDayWithDate(selectedDate)
                                    
                                    if selectedDay == fullDayFormat {
                                        // Deselect if tapping the same day
                                        withAnimation(.easeOut(duration: 0.3)) {
                                            selectedDay = nil
                                            selectedSteps = 0
                                            glowPulse = false
                                            typingSteps = 0
                                        }
                                    } else {
                                        // Select new day with full format
                                        selectedDay = fullDayFormat
                                        if let steps = stepModel.weeklySteps[selectedDate] {
                                            selectedSteps = steps
                                            
                                            // Start futuristic animations
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                glowPulse = true
                                                scanningPosition = -200
                                            }
                                            
                                            // Animate typing effect for numbers
                                            animateTypingEffect(targetSteps: steps)
                                            
                                            // Start scanning effect
                                            withAnimation(.linear(duration: 2.0)) {
                                                scanningPosition = 200
                                            }
                                        }
                                    }
                                }
                            }
                        }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                
                // Futuristic glow overlay when selection is active
                if selectedDay != nil {
                    Rectangle()
                        .fill(Color.clear)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.green.opacity(0.3), .cyan.opacity(0.3)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: glowPulse ? 2 : 1
                                )
                                .shadow(color: .green.opacity(0.4), radius: glowPulse ? 15 : 8)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
                        )
                }
            }
            .frame(height: 250)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
                    .scaleEffect(selectedDay != nil ? (glowPulse ? 1.02 : 1.01) : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
            )
            .padding()
            
            // Selected day details with futuristic animations
            if let selectedDay = selectedDay {
                createSelectionCard(selectedDay: selectedDay)
            }
            
            // Statistics summary
            VStack(spacing: 20) {
                StatCard(
                    title: "Daily Average".localized,
                    value: "\(averageDailySteps())",
                    icon: "figure.walk",
                    color1: .blue,
                    color2: .cyan
                )
                
                StatCard(
                    title: "Weekly Total".localized,
                    value: "\(totalWeeklySteps())",
                    icon: "flame.fill",
                    color1: .orange,
                    color2: .red
                )
                
                StatCard(
                    title: "Best Day".localized,
                    value: String(format: "%lld steps".localized, bestDaySteps()),
                    icon: "star.fill",
                    color1: .yellow,
                    color2: .orange
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "101010")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
        )
    }
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func formatDayWithDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd-MM-yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDateForDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, yyyy"
        return formatter.string(from: date)
    }
    
    private func extractDayFromFullFormat(_ fullFormat: String) -> String {
        return String(fullFormat.prefix(3)) // Extrae "Wed" de "Wed 05-09-2025"
    }
    
    private func parseDateFromFullFormat(_ fullFormat: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd-MM-yyyy"
        return formatter.date(from: fullFormat)
    }
    
    private func averageDailySteps() -> Int { StatsCalculator.averageDailySteps(weeklySteps: stepModel.weeklySteps) }
    private func totalWeeklySteps() -> Int { StatsCalculator.totalWeeklySteps(weeklySteps: stepModel.weeklySteps) }
    private func bestDaySteps() -> Int { StatsCalculator.bestDaySteps(weeklySteps: stepModel.weeklySteps) }
    
    // MARK: - Futuristic Animation Functions
    private func animateTypingEffect(targetSteps: Int) {
        typingSteps = 0
        let stepIncrement = max(1, targetSteps / 30) // Animate over ~30 frames
        let duration = 1.5 // Total duration in seconds
        let frameInterval = duration / Double(targetSteps / stepIncrement)
        
        Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.1)) {
                if typingSteps < targetSteps {
                    typingSteps = min(typingSteps + stepIncrement, targetSteps)
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    // MARK: - Chart Creation Functions
    private func createBarMark(for date: Date, steps: Int) -> some ChartContent {
        let dayName = formatDay(date)
        let fullDayFormat = formatDayWithDate(date)
        let isSelected = selectedDay == fullDayFormat
        
        return BarMark(
            x: .value("Day".localized, dayName),
            y: .value("Steps".localized, steps)
        )
        .foregroundStyle(barGradient(for: isSelected))
        .cornerRadius(8)
        .opacity(barOpacity(for: isSelected))
    }
    
    private func barGradient(for isSelected: Bool) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: isSelected ? [.green, .cyan] : [.blue, .purple]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    private func barOpacity(for isSelected: Bool) -> Double {
        selectedDay == nil || isSelected ? 1.0 : 0.6
    }
    
    // MARK: - Selection Card Creation
    @ViewBuilder
    private func createSelectionCard(selectedDay: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                HStack {
                    createAnimatedIcon()
                    createDayInfo(selectedDay: selectedDay)
                    Spacer()
                    createStepsInfo()
                }
                .padding()
                .background(createCardBackground())
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            
            createInstructionText()
        }
        .padding(.horizontal)
        .scaleEffect(glowPulse ? 1.0 : 0.95)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top))
        ))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedDay)
    }
    
    @ViewBuilder
    private func createAnimatedIcon() -> some View {
        ZStack {
            Circle()
                .fill(iconGradient())
                .frame(width: 50, height: 50)
                .scaleEffect(glowPulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
            
            Image(systemName: "calendar.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
                .shadow(color: .cyan, radius: glowPulse ? 8 : 4)
                .rotationEffect(.degrees(glowPulse ? 5 : 0))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
        }
    }
    
    @ViewBuilder
    private func createDayInfo(selectedDay: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Selected Day".localized)
                .font(.caption)
                .foregroundColor(.gray)
            
            // Parse and display day and date separately for better visual hierarchy
            if selectedDay.contains(" ") {
                let components = selectedDay.components(separatedBy: " ")
                if components.count >= 2 {
                    Text(components[0]) // Day name (e.g., "Wed")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.8), radius: 2)
                    
                    // Convert technical date format to user-friendly format
                    if let date = parseDateFromFullFormat(selectedDay) {
                        Text(formatDateForDisplay(date)) // e.g., "Sep 05, 2025"
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 1)
                    } else {
                        Text(components[1]) // Fallback to original format
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 1)
                    }
                } else {
                    Text(selectedDay)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.8), radius: 2)
                }
            } else {
                Text(selectedDay)
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .green.opacity(0.8), radius: 2)
            }
        }
    }
    
    @ViewBuilder
    private func createStepsInfo() -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Steps".localized)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(typingSteps)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .shadow(color: .cyan, radius: 4)
                .contentTransition(.numericText())
        }
    }
    
    @ViewBuilder
    private func createCardBackground() -> some View {
        ZStack {
            createGlowBackground()
            createAnimatedBorder()
            createScanningLine()
        }
    }
    
    @ViewBuilder
    private func createGlowBackground() -> some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.4))
            .shadow(color: .green.opacity(0.3), radius: glowPulse ? 20 : 10)
            .scaleEffect(glowPulse ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
    
    @ViewBuilder
    private func createAnimatedBorder() -> some View {
        RoundedRectangle(cornerRadius: 15)
            .stroke(borderGradient(), lineWidth: glowPulse ? 3 : 2)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
    
    @ViewBuilder
    private func createScanningLine() -> some View {
        Rectangle()
            .fill(scanLineGradient())
            .frame(width: 4)
            .offset(x: scanningPosition)
            .clipped()
            .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: scanningPosition)
    }
    
    @ViewBuilder
    private func createInstructionText() -> some View {
        Text("Tap the same day to deselect".localized)
            .font(.caption)
            .foregroundColor(.gray.opacity(0.7))
            .shadow(color: .green.opacity(0.3), radius: 1)
            .padding(.bottom, 5)
            .opacity(glowPulse ? 0.8 : 0.6)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
    
    // MARK: - Gradient Helpers
    private func iconGradient() -> RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
            center: .center,
            startRadius: 0,
            endRadius: 25
        )
    }
    
    private func borderGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .green.opacity(glowPulse ? 1.0 : 0.6), location: 0),
                .init(color: .cyan.opacity(glowPulse ? 0.8 : 0.4), location: 0.5),
                .init(color: .green.opacity(glowPulse ? 1.0 : 0.6), location: 1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private func scanLineGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .cyan.opacity(0.6), .clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color1: Color
    let color2: Color
    
    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [color1.opacity(0.7), color2.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.2))
                .shadow(color: color1.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
} 
