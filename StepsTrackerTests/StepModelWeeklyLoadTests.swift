import XCTest
@testable import StepsTracker

@MainActor
final class StepModelWeeklyLoadTests: XCTestCase {
    func testFreshDashboardRequiresExplicitHealthPermissionRequest() {
        let provider = StepDataProviderStub()
        let model = makeModel(provider: provider, clock: TestClock(now: date(day: 26)))

        XCTAssertEqual(model.dataState, .needsHealthPermission)
        XCTAssertEqual(provider.authorizationRequests, 0)
    }

    func testRequestingHealthPermissionStartsObservingAndCompletesObserverAfterRefresh() async {
        let clock = TestClock(now: date(day: 26))
        let provider = StepDataProviderStub()
        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 250, count: 7))
        let model = makeModel(provider: provider, clock: clock)

        await model.requestHealthPermission()

        XCTAssertEqual(provider.authorizationRequests, 1)
        XCTAssertEqual(provider.observerStarts, 1)
        XCTAssertEqual(model.dataState, .ready)

        provider.stepsByDate = steps(for: clock.now, values: Array(repeating: 900, count: 7))
        await provider.sendObservedUpdate()

        XCTAssertEqual(model.todaySteps, 900)
        XCTAssertEqual(provider.completedObservedUpdates, 1)
    }

    func testAuthorizationFailuresAreExposedAsPermissionAndAvailabilityStates() async {
        let provider = StepDataProviderStub()
        let settings = InMemoryGoalSettingsStore()
        let model = StepModel(
            enableSideEffects: false,
            stepDataProvider: provider,
            settingsStore: settings,
            notificationScheduler: NotificationSchedulerSpy(),
            now: { date(day: 26) }
        )

        provider.authorizationError = StepDataProviderError.authorizationFailed
        await model.requestHealthPermission()
        XCTAssertEqual(model.dataState, .needsHealthPermission)
        XCTAssertFalse(settings.hasRequestedHealthAccess)

        provider.authorizationError = StepDataProviderError.healthDataUnavailable
        await model.requestHealthPermission()
        XCTAssertEqual(model.dataState, .unavailable)
    }

    func testReminderIsOptInAndPersistsOnlyAfterAuthorization() async {
        let notifications = NotificationSchedulerSpy()
        let settings = InMemoryGoalSettingsStore()
        let model = StepModel(
            enableSideEffects: false,
            stepDataProvider: StepDataProviderStub(),
            settingsStore: settings,
            notificationScheduler: notifications,
            now: { Self.today }
        )

        XCTAssertFalse(model.isReminderEnabled)
        XCTAssertEqual(notifications.reminderSchedules, 0)

        await model.setReminderEnabled(true)
        await model.setReminderTime(date(hour: 18, minute: 30))

        XCTAssertTrue(model.isReminderEnabled)
        XCTAssertEqual(notifications.authorizationRequests, 1)
        XCTAssertEqual(notifications.reminderSchedules, 2)
        XCTAssertEqual(settings.reminderTime, date(hour: 18, minute: 30))
    }

    #if DEBUG && targetEnvironment(simulator)
    func testDemoDataLoadsWithoutHealthAuthorization() async {
        let clock = TestClock(now: date(day: 26))
        let settings = InMemoryGoalSettingsStore()
        let model = StepModel(
            enableSideEffects: false,
            stepDataProvider: DemoStepDataProvider(now: { clock.now }),
            settingsStore: settings,
            notificationScheduler: NotificationSchedulerSpy(),
            now: { clock.now }
        )

        XCTAssertTrue(model.isUsingDemoData)
        XCTAssertEqual(model.dataState, .loading)

        await model.refresh()

        XCTAssertEqual(model.dataState, .ready)
        XCTAssertEqual(model.dailySteps.count, 7)
        XCTAssertEqual(model.todaySteps, 8_450)
        XCTAssertFalse(settings.hasRequestedHealthAccess)
    }
    #endif

    private func makeModel(provider: StepDataProviderStub, clock: TestClock) -> StepModel {
        StepModel(
            enableSideEffects: false,
            stepDataProvider: provider,
            settingsStore: InMemoryGoalSettingsStore(),
            notificationScheduler: NotificationSchedulerSpy(),
            now: { clock.now }
        )
    }

    private static let today = date(day: 26)
}

@MainActor
final class StepDataProviderStub: StepDataProviding {
    var stepsByDate: [Date: Int] = [:]
    var error: Error?
    var authorizationError: Error?
    private(set) var authorizationRequests = 0
    private(set) var observerStarts = 0
    private(set) var completedObservedUpdates = 0
    private var observedUpdate: (@Sendable @MainActor () async -> Void)?

    func requestAuthorization() async throws {
        authorizationRequests += 1
        if let authorizationError {
            throw authorizationError
        }
    }

    func steps(for day: Date) async throws -> Int {
        if let error {
            throw error
        }
        return stepsByDate[day] ?? 0
    }

    func startObservingChanges(onUpdate: @escaping @Sendable @MainActor () async -> Void) async throws {
        observerStarts += 1
        observedUpdate = onUpdate
    }

    func sendObservedUpdate() async {
        await observedUpdate?()
        completedObservedUpdates += 1
    }
}

@MainActor
final class NotificationSchedulerSpy: NotificationScheduling {
    var requestedStatus: NotificationAuthorizationStatus = .authorized
    private var hasRequestedAuthorization = false
    private(set) var authorizationRequests = 0
    private(set) var reminderSchedules = 0
    private(set) var goalNotifications = 0

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        hasRequestedAuthorization ? requestedStatus : .notDetermined
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        authorizationRequests += 1
        hasRequestedAuthorization = true
        return requestedStatus
    }

    func scheduleDailyReminder(at time: Date) async throws {
        reminderSchedules += 1
    }

    func cancelDailyReminder() async {}

    func scheduleGoalAchievedNotification() async throws {
        goalNotifications += 1
    }
}

@MainActor
final class InMemoryGoalSettingsStore: GoalSettingsStoring {
    var goalSteps: Int?
    var hasRequestedHealthAccess = false
    var isReminderEnabled = false
    var reminderTime = date(hour: 10, minute: 0)
    var lastGoalNotificationDay: Date?

    init(goalSteps: Int? = nil) {
        self.goalSteps = goalSteps
    }
}

@MainActor
final class TestClock {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

func steps(for today: Date, values: [Int]) -> [Date: Int] {
    let calendar = Calendar(identifier: .gregorian)
    return Dictionary(uniqueKeysWithValues: values.enumerated().map { index, value in
        let offset = values.count - index - 1
        let day = calendar.date(byAdding: .day, value: -offset, to: today)!
        return (calendar.startOfDay(for: day), value)
    })
}

func date(day: Int) -> Date {
    Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 7, day: day))!
}

func date(hour: Int, minute: Int) -> Date {
    Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour, minute: minute))!
}
