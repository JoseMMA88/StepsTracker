import XCTest
@testable import StepsTracker

final class StatsCalculatorTests: XCTestCase {
    func testCalculationsUseTypedDailySteps() {
        let steps = [
            DailyStep(date: date(day: 1), steps: 1_000),
            DailyStep(date: date(day: 2), steps: 2_000),
            DailyStep(date: date(day: 3), steps: 3_000)
        ]

        XCTAssertEqual(StatsCalculator.averageDailySteps(dailySteps: steps), 2_000)
        XCTAssertEqual(StatsCalculator.totalWeeklySteps(dailySteps: steps), 6_000)
        XCTAssertEqual(StatsCalculator.bestDaySteps(dailySteps: steps), 3_000)
    }

    func testCalculationsForEmptyCollectionReturnZero() {
        XCTAssertEqual(StatsCalculator.averageDailySteps(dailySteps: []), 0)
        XCTAssertEqual(StatsCalculator.totalWeeklySteps(dailySteps: []), 0)
        XCTAssertEqual(StatsCalculator.bestDaySteps(dailySteps: []), 0)
    }

    func testWeeklySummaryUsesCalendarWeekStartTotalAndDailyAverage() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let dailySteps = [
            DailyStep(date: date(year: 2026, month: 7, day: 7, hour: 12), steps: 8_000),
            DailyStep(date: date(year: 2026, month: 7, day: 12, hour: 12), steps: 10_000)
        ]

        let summary = StatsCalculator.weeklySummary(for: dailySteps, calendar: calendar)

        XCTAssertEqual(summary?.weekStart, date(year: 2026, month: 7, day: 6))
        XCTAssertEqual(summary?.totalSteps, 18_000)
        XCTAssertEqual(summary?.averageDailySteps, 9_000)
    }

    private func date(day: Int) -> Date {
        date(year: 2026, month: 7, day: day)
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }
}
