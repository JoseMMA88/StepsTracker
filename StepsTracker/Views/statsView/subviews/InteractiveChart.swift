import SwiftUI
import Charts

// MARK: - Interactive Chart Component
struct InteractiveChart: View {
    let weeklySteps: [Date: Int]
    @Binding var selectedDay: String?
    @Binding var selectedSteps: Int
    @Binding var glowPulse: Bool
    @Binding var typingSteps: Int
    @Binding var scanningPosition: CGFloat
    
    var body: some View {
        ZStack {
            Chart {
                ForEach(weeklySteps.sorted(by: { $0.key < $1.key }), id: \.key) { date, steps in
                    createBarMark(for: date, steps: steps)
                }
            }
            .chartXSelection(value: .constant(selectedDay))
            .chartGesture { chartProxy in
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        handleChartTap(at: value.location, chartProxy: chartProxy)
                    }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            
            // Sutil overlay cuando hay selección, sin animaciones agresivas
            if selectedDay != nil {
                ChartGlowOverlay(glowPulse: $glowPulse)
            }
        }
        .frame(height: 250)
        .padding()
        .background(
            ChartBackground(selectedDay: selectedDay, glowPulse: $glowPulse)
        )
        .padding()
    }
    
    // MARK: - Chart Interaction Logic
    private func handleChartTap(at location: CGPoint, chartProxy: ChartProxy) {
        if let day: String = chartProxy.value(atX: location.x) {
            // Find the date that corresponds to this day
            if let selectedDate = weeklySteps.keys.first(where: { DateFormatter.dayOfWeek($0) == day }) {
                let fullDayFormat = DateFormatter.dayWithDate(selectedDate)
                
                if selectedDay == fullDayFormat {
                    // Deselect if tapping the same day
                    deselectDay()
                } else if weeklySteps[selectedDate] != 0 {
                    // Select new day with full format
                    selectDay(fullDayFormat, steps: weeklySteps[selectedDate] ?? 0)
                }
            }
        }
    }
    
    private func selectDay(_ dayFormat: String, steps: Int) {
        selectedDay = dayFormat
        selectedSteps = steps
        
        // Start futuristic animations
        withAnimation(.easeInOut(duration: 0.3)) {
            glowPulse = true
            scanningPosition = -200
        }
        
        // Animate typing effect for numbers
        AnimationManager.animateTypingEffect(targetSteps: steps, typingSteps: $typingSteps)
        
        // Start scanning effect
        withAnimation(.linear(duration: 2.0)) {
            scanningPosition = 200
        }
    }
    
    private func deselectDay() {
        withAnimation(.easeOut(duration: 0.3)) {
            selectedDay = nil
            selectedSteps = 0
            glowPulse = false
            typingSteps = 0
        }
    }
    
    // MARK: - Chart Bar Creation
    private func createBarMark(for date: Date, steps: Int) -> some ChartContent {
        let dayName = DateFormatter.dayOfWeek(date)
        let fullDayFormat = DateFormatter.dayWithDate(date)
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
}

// MARK: - Chart Visual Components
struct ChartGlowOverlay: View {
    @Binding var glowPulse: Bool
    
    var body: some View {
        // Foco suave, sin animar el grosor del borde ni repetir forever
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0.18),
                        Color.cyan.opacity(0.18)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 2
            )
            .shadow(color: Color.green.opacity(glowPulse ? 0.25 : 0.12), radius: glowPulse ? 10 : 6)
            .opacity(glowPulse ? 1.0 : 0.85)
            // Transiciones suaves solo cuando cambia glowPulse, sin bucles
            .animation(.easeInOut(duration: 0.6), value: glowPulse)
            .padding(2)
            .compositingGroup()
    }
}

struct ChartBackground: View {
    let selectedDay: String?
    @Binding var glowPulse: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.2))
            // Suaviza el “pulso” pero sin repeatForever para no sobrecargar
            .opacity(selectedDay != nil ? (glowPulse ? 1.0 : 0.95) : 1.0)
            .animation(.easeInOut(duration: 0.6), value: glowPulse)
    }
}
