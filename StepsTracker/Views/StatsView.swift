import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var stepModel: StepModel
    
    var body: some View {
        VStack {
            Text("Weekly Statistics")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.top)
            
            // Weekly chart
            Chart {
                ForEach(stepModel.weeklySteps.sorted(by: { $0.key < $1.key }), id: \.key) { date, steps in
                    BarMark(
                        x: .value("Day", formatDay(date)),
                        y: .value("Steps", steps)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(8)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.2))
            )
            .padding()
            
            // Statistics summary
            VStack(spacing: 20) {
                StatCard(
                    title: "Daily Average",
                    value: "\(averageDailySteps())",
                    icon: "figure.walk",
                    color1: .blue,
                    color2: .cyan
                )
                
                StatCard(
                    title: "Weekly Total",
                    value: "\(totalWeeklySteps())",
                    icon: "flame.fill",
                    color1: .orange,
                    color2: .red
                )
                
                StatCard(
                    title: "Best Day",
                    value: "\(bestDaySteps()) steps",
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
    
    private func averageDailySteps() -> Int {
        guard !stepModel.weeklySteps.isEmpty else { return 0 }
        let total = stepModel.weeklySteps.values.reduce(0, +)
        let count = stepModel.weeklySteps.count
        guard count > 0 else { return 0 }
        return total / count
    }
    
    private func totalWeeklySteps() -> Int {
        return stepModel.weeklySteps.values.reduce(0, +)
    }
    
    private func bestDaySteps() -> Int {
        return stepModel.weeklySteps.values.max() ?? 0
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