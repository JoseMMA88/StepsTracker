import Foundation

/// Provides pure, reusable calculations for steps statistics.
struct StatsCalculator {
    /// Returns the arithmetic mean of steps across provided days. Returns 0 if empty.
    static func averageDailySteps(weeklySteps: [Date: Int]) -> Int {
        guard !weeklySteps.isEmpty else { return 0 }
        let total = weeklySteps.values.reduce(0, +)
        let count = weeklySteps.count
        guard count > 0 else { return 0 }
        return total / count
    }

    /// Returns the sum of steps across provided days.
    static func totalWeeklySteps(weeklySteps: [Date: Int]) -> Int {
        return weeklySteps.values.reduce(0, +)
    }

    /// Returns the maximum steps value for the best day. Returns 0 if empty.
    static func bestDaySteps(weeklySteps: [Date: Int]) -> Int {
        return weeklySteps.values.max() ?? 0
    }
}


