import XCTest
@testable import StepsTracker

final class StatsCalculatorTests: XCTestCase {
    func testAverageDailySteps_empty_returnsZero() {
        let average = StatsCalculator.averageDailySteps(weeklySteps: [:])
        XCTAssertEqual(average, 0)
    }

    func testAverageDailySteps_nonEmpty_integerDivision() {
        // 1000 + 2000 + 3000 = 6000 / 3 = 2000
        let now = Date()
        let calendar = Calendar.current
        let steps: [Date: Int] = [
            calendar.startOfDay(for: now): 1000,
            calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!: 2000,
            calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!: 3000
        ]
        let average = StatsCalculator.averageDailySteps(weeklySteps: steps)
        XCTAssertEqual(average, 2000)
    }

    func testTotalWeeklySteps_sumsAllValues() {
        let now = Date()
        let calendar = Calendar.current
        let steps: [Date: Int] = [
            calendar.startOfDay(for: now): 1200,
            calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!: 800,
            calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!: 0
        ]
        let total = StatsCalculator.totalWeeklySteps(weeklySteps: steps)
        XCTAssertEqual(total, 2000)
    }

    func testBestDaySteps_returnsMaxOrZero() {
        XCTAssertEqual(StatsCalculator.bestDaySteps(weeklySteps: [:]), 0)

        let now = Date()
        let calendar = Calendar.current
        let steps: [Date: Int] = [
            calendar.startOfDay(for: now): 500,
            calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!: 1200,
            calendar.date(byAdding: .day, value: -2, to: calendar.startOfDay(for: now))!: 300
        ]
        XCTAssertEqual(StatsCalculator.bestDaySteps(weeklySteps: steps), 1200)
    }
}


