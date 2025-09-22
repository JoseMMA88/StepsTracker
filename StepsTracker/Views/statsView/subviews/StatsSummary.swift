import SwiftUI

// MARK: - Statistics Summary Component
struct StatsSummary: View {
    let weeklySteps: [Date: Int]
    
    var body: some View {
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
    }
    
    // MARK: - Statistics Calculations
    private func averageDailySteps() -> Int {
        StatsCalculator.averageDailySteps(weeklySteps: weeklySteps)
    }
    
    private func totalWeeklySteps() -> Int {
        StatsCalculator.totalWeeklySteps(weeklySteps: weeklySteps)
    }
    
    private func bestDaySteps() -> Int {
        StatsCalculator.bestDaySteps(weeklySteps: weeklySteps)
    }
}

// MARK: - Individual Statistic Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color1: Color
    let color2: Color
    
    var body: some View {
        HStack {
            IconSection(icon: icon, color1: color1, color2: color2)
            InfoSection(title: title, value: value)
            Spacer()
        }
        .padding()
        .background(cardBackground)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.2))
            .shadow(color: color1.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - StatCard Components
struct IconSection: View {
    let icon: String
    let color1: Color
    let color2: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(iconGradient)
                .frame(width: 50, height: 50)
            
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }
    
    private var iconGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [color1.opacity(0.7), color2.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct InfoSection: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}
