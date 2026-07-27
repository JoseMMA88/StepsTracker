import XCTest
@testable import StepsTracker

@MainActor
final class StepModelFetchTodayTests: XCTestCase {
    func testRefreshUpdatesTodayAndReplacesTheSevenDaySeriesAtomically() async {
        let clock = TestClock(now: date(day: 26))
        let provider = StepDataProviderStub()
        provider.stepsByDate = steps(for: clock.now, values: [100, 200, 300, 400, 500, 600, 700])
        let model = makeModel(provider: provider, clock: clock)

        await model.refresh()

        XCTAssertEqual(model.dataState, .ready)
        XCTAssertEqual(model.dailySteps.count, 7)
        XCTAssertEqual(model.todaySteps, 700)
        XCTAssertEqual(model.dailySteps.last?.steps, 700)

        clock.now = date(day: 27)
        provider.stepsByDate = steps(for: clock.now, values: [10, 20, 30, 40, 50, 60, 70])

        await model.refresh()

        XCTAssertEqual(model.dailySteps.count, 7)
        XCTAssertEqual(model.dailySteps.first?.date, date(day: 21))
        XCTAssertEqual(model.dailySteps.last?.date, date(day: 27))
        XCTAssertEqual(model.todaySteps, 70)
    }

    func testRefreshKeepsPreviousSeriesWhenOneDayFails() async {
        let clock = TestClock(now: date(day: 26))
        let provider = StepDataProviderStub()
        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 100, count: 7))
        let model = makeModel(provider: provider, clock: clock)
        await model.refresh()
        let previousSteps = model.dailySteps

        provider.error = StepDataProviderError.queryFailed("HealthKit query failed")
        await model.refresh()

        XCTAssertEqual(model.dailySteps, previousSteps)
        XCTAssertEqual(model.dataState, .failed("HealthKit query failed"))
    }

    func testRefreshKeepsTheDashboardReadyWhileAnUpdateIsInFlight() async {
        let clock = TestClock(now: date(day: 26))
        let provider = StepDataProviderStub()
        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 100, count: 7))
        let model = makeModel(provider: provider, clock: clock)
        await model.refresh()

        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 500, count: 7))
        provider.suspendNextStepRequest = true
        let updateStarted = expectation(description: "Refresh starts loading step data")
        provider.onStepRequestSuspended = { updateStarted.fulfill() }

        let refreshTask = Task { await model.refresh() }
        await fulfillment(of: [updateStarted], timeout: 1)

        XCTAssertTrue(model.isUpdating)
        XCTAssertEqual(model.dataState, .ready)
        XCTAssertEqual(model.todaySteps, 100)

        provider.resumeSuspendedStepRequest()
        await refreshTask.value

        XCTAssertFalse(model.isUpdating)
        XCTAssertEqual(model.dataState, .ready)
        XCTAssertEqual(model.todaySteps, 500)
    }

    func testGoalAchievementIsScheduledOnlyOncePerDay() async {
        let clock = TestClock(now: date(day: 26))
        let provider = StepDataProviderStub()
        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 1_000, count: 7))
        let notifications = NotificationSchedulerSpy()
        let model = makeModel(provider: provider, clock: clock, notifications: notifications)
        model.goalSteps = 1_000

        await model.refresh()
        await model.refresh()

        XCTAssertEqual(notifications.goalNotifications, 1)

        clock.now = date(day: 27)
        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 1_000, count: 7))
        await model.refresh()

        XCTAssertEqual(notifications.goalNotifications, 2)
    }

    func testStatisticsHistoryLoadsCalendarWeeksWithoutReplacingTodayData() async throws {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 26))!
        let clock = TestClock(now: today)
        let provider = StepDataProviderStub()
        let previousWeek = calendar.date(byAdding: .day, value: -13, to: today)!
        let currentWeek = calendar.date(byAdding: .day, value: -6, to: today)!

        provider.stepsByDate = weeklySteps(
            startingOn: previousWeek,
            values: [100, 200, 300, 400, 500, 600, 700],
            calendar: calendar
        )
        provider.stepsByDate.merge(
            weeklySteps(
                startingOn: currentWeek,
                values: [800, 900, 1_000, 1_100, 1_200, 1_300, 1_400],
                calendar: calendar
            )
        ) { _, latest in latest }

        let model = StepModel(
            enableSideEffects: false,
            stepDataProvider: provider,
            settingsStore: InMemoryGoalSettingsStore(),
            notificationScheduler: NotificationSchedulerSpy(),
            now: { clock.now },
            calendar: calendar
        )
        await model.refresh()
        let dashboardSteps = model.dailySteps

        let history = try await model.statisticsHistory(forWeekContaining: today, weeksToDisplay: 2)

        XCTAssertEqual(history.selectedWeekStart, currentWeek)
        XCTAssertEqual(history.dailySteps.map(\.steps), [800, 900, 1_000, 1_100, 1_200, 1_300, 1_400])
        XCTAssertEqual(history.weeklySummaries.map(\.totalSteps), [2_800, 7_700])
        XCTAssertEqual(history.weeklySummaries.map(\.averageDailySteps), [400, 1_100])
        XCTAssertEqual(model.dailySteps, dashboardSteps)
    }

    private func makeModel(
        provider: StepDataProviderStub,
        clock: TestClock,
        notifications: NotificationSchedulerSpy? = nil
    ) -> StepModel {
        StepModel(
            enableSideEffects: false,
            stepDataProvider: provider,
            settingsStore: InMemoryGoalSettingsStore(),
            notificationScheduler: notifications ?? NotificationSchedulerSpy(),
            now: { clock.now }
        )
    }

    private func weeklySteps(
        startingOn weekStart: Date,
        values: [Int],
        calendar: Calendar
    ) -> [Date: Int] {
        Dictionary(uniqueKeysWithValues: values.enumerated().map { offset, value in
            (calendar.date(byAdding: .day, value: offset, to: weekStart)!, value)
        })
    }
}
