import Foundation

struct WeeklyStepSummary: Identifiable, Hashable, Sendable {
    let weekStart: Date
    let totalSteps: Int
    let averageDailySteps: Int

    var id: Date { weekStart }
}

struct StatsCalculator {
    static func averageDailySteps(dailySteps: [DailyStep]) -> Int {
        guard !dailySteps.isEmpty else { return 0 }
        return totalWeeklySteps(dailySteps: dailySteps) / dailySteps.count
    }

    static func totalWeeklySteps(dailySteps: [DailyStep]) -> Int {
        dailySteps.reduce(0) { $0 + $1.steps }
    }

    static func bestDaySteps(dailySteps: [DailyStep]) -> Int {
        dailySteps.map(\.steps).max() ?? 0
    }

    static func weeklySummary(
        for dailySteps: [DailyStep],
        calendar: Calendar = .autoupdatingCurrent
    ) -> WeeklyStepSummary? {
        guard let firstDay = dailySteps.map(\.date).min(),
              let interval = calendar.dateInterval(of: .weekOfYear, for: firstDay) else {
            return nil
        }

        return WeeklyStepSummary(
            weekStart: interval.start,
            totalSteps: totalWeeklySteps(dailySteps: dailySteps),
            averageDailySteps: averageDailySteps(dailySteps: dailySteps)
        )
    }

    static func averageDailySteps(weeklySteps: [Date: Int]) -> Int {
        averageDailySteps(dailySteps: dailySteps(from: weeklySteps))
    }

    static func totalWeeklySteps(weeklySteps: [Date: Int]) -> Int {
        totalWeeklySteps(dailySteps: dailySteps(from: weeklySteps))
    }

    static func bestDaySteps(weeklySteps: [Date: Int]) -> Int {
        bestDaySteps(dailySteps: dailySteps(from: weeklySteps))
    }

    private static func dailySteps(from weeklySteps: [Date: Int]) -> [DailyStep] {
        weeklySteps.map { DailyStep(date: $0.key, steps: $0.value) }
    }
}
