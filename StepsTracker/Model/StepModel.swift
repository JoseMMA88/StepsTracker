import Foundation
import Observation

enum StepDashboardState: Equatable {
    case loading
    case ready
    case needsHealthPermission
    case unavailable
    case failed(String)
}

struct StepStatisticsHistory: Equatable, Sendable {
    let selectedWeekStart: Date
    let dailySteps: [DailyStep]
    let weeklySummaries: [WeeklyStepSummary]
}

@MainActor
protocol GoalSettingsStoring: AnyObject {
    var goalSteps: Int? { get set }
    var hasRequestedHealthAccess: Bool { get set }
    var isReminderEnabled: Bool { get set }
    var reminderTime: Date { get set }
    var lastGoalNotificationDay: Date? { get set }
}

@MainActor
final class UserDefaultsGoalSettingsStore: GoalSettingsStoring {
    private enum Key {
        static let goalSteps = "goalSteps"
        static let hasRequestedHealthAccess = "hasRequestedHealthAccess"
        static let isReminderEnabled = "isReminderEnabled"
        static let reminderMinutes = "reminderMinutes"
        static let lastGoalNotificationDay = "lastGoalNotificationDay"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    init(defaults: UserDefaults = .standard, calendar: Calendar = .autoupdatingCurrent) {
        self.defaults = defaults
        self.calendar = calendar
    }

    var goalSteps: Int? {
        get {
            guard defaults.object(forKey: Key.goalSteps) != nil else { return nil }
            return defaults.integer(forKey: Key.goalSteps)
        }
        set { defaults.set(newValue, forKey: Key.goalSteps) }
    }

    var hasRequestedHealthAccess: Bool {
        get { defaults.bool(forKey: Key.hasRequestedHealthAccess) }
        set { defaults.set(newValue, forKey: Key.hasRequestedHealthAccess) }
    }

    var isReminderEnabled: Bool {
        get { defaults.bool(forKey: Key.isReminderEnabled) }
        set { defaults.set(newValue, forKey: Key.isReminderEnabled) }
    }

    var reminderTime: Date {
        get {
            let defaultMinutes = 10 * 60
            let minutes = defaults.object(forKey: Key.reminderMinutes) == nil
                ? defaultMinutes
                : defaults.integer(forKey: Key.reminderMinutes)
            return time(for: minutes)
        }
        set {
            let components = calendar.dateComponents([.hour, .minute], from: newValue)
            let minutes = (components.hour ?? 10) * 60 + (components.minute ?? 0)
            defaults.set(minutes, forKey: Key.reminderMinutes)
        }
    }

    var lastGoalNotificationDay: Date? {
        get { defaults.object(forKey: Key.lastGoalNotificationDay) as? Date }
        set { defaults.set(newValue, forKey: Key.lastGoalNotificationDay) }
    }

    private func time(for minutes: Int) -> Date {
        let hour = max(0, min(minutes / 60, 23))
        let minute = max(0, min(minutes % 60, 59))
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}

@MainActor
@Observable
final class StepModel {
    private static let defaultGoalSteps = 10_000
    private static let weeklyDayCount = 7

    var todaySteps = 0
    var goalSteps: Int {
        didSet { persistValidatedGoal() }
    }
    private(set) var dailySteps: [DailyStep] = []
    private(set) var dataState: StepDashboardState = .loading
    private(set) var isRefreshing = false
    let isUsingDemoData: Bool
    private(set) var isReminderEnabled: Bool
    private(set) var reminderTime: Date
    private(set) var notificationAuthorizationStatus: NotificationAuthorizationStatus = .notDetermined

    var weeklySteps: [Date: Int] {
        Dictionary(uniqueKeysWithValues: dailySteps.map { ($0.date, $0.steps) })
    }

    var isUpdating: Bool {
        isRefreshing || dataState == .loading
    }

    @ObservationIgnored private let stepDataProvider: StepDataProviding
    @ObservationIgnored private let settingsStore: GoalSettingsStoring
    @ObservationIgnored private let notificationScheduler: NotificationScheduling
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var hasStartedObserving = false
    @ObservationIgnored private var refreshID = 0
    @ObservationIgnored private var statisticsWeekCache: [Date: (end: Date, days: [DailyStep])] = [:]

    init(
        enableSideEffects: Bool = true,
        stepDataProvider: StepDataProviding? = nil,
        settingsStore: GoalSettingsStoring? = nil,
        notificationScheduler: NotificationScheduling? = nil,
        now: @escaping @MainActor () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let stepDataProvider = stepDataProvider ?? HealthKitStepDataProvider(calendar: calendar)
        self.stepDataProvider = stepDataProvider
        let settingsStore = settingsStore ?? UserDefaultsGoalSettingsStore()
        self.settingsStore = settingsStore
        self.notificationScheduler = notificationScheduler ?? NotificationManager.shared
        self.now = now
        self.calendar = calendar
        self.goalSteps = Self.validGoal(settingsStore.goalSteps ?? Self.defaultGoalSteps)
        self.isReminderEnabled = settingsStore.isReminderEnabled
        self.reminderTime = settingsStore.reminderTime
        self.isUsingDemoData = !stepDataProvider.requiresHealthAuthorization
        self.dataState = !stepDataProvider.requiresHealthAuthorization || settingsStore.hasRequestedHealthAccess
            ? .loading
            : .needsHealthPermission

        guard enableSideEffects else { return }
        Task { [weak self] in
            await self?.initializeDashboard()
        }
    }

    func progress() -> Double {
        guard goalSteps > 0, todaySteps >= 0 else { return 0 }
        return min(Double(todaySteps) / Double(goalSteps), 1)
    }

    func refresh() async {
        refreshID += 1
        let currentRefreshID = refreshID
        let refreshDate = now()
        let previousState = dataState
        statisticsWeekCache.removeAll()
        isRefreshing = true

        if previousState != .ready {
            dataState = .loading
        }

        defer {
            if currentRefreshID == refreshID {
                isRefreshing = false
            }
        }

        do {
            let refreshedSteps = try await loadWeek(containing: refreshDate)
            guard currentRefreshID == refreshID else { return }
            dailySteps = refreshedSteps
            todaySteps = refreshedSteps.last?.steps ?? 0
            dataState = .ready
            await notifyGoalAchievementIfNeeded(for: calendar.startOfDay(for: refreshDate))
        } catch is CancellationError {
            guard currentRefreshID == refreshID else { return }
            dataState = previousState
        } catch {
            guard currentRefreshID == refreshID else { return }
            dataState = state(for: error)
        }
    }

    func updateGoal(_ newGoal: Int) async {
        goalSteps = newGoal
    }

    func setReminderEnabled(_ isEnabled: Bool) async {
        guard isEnabled else {
            isReminderEnabled = false
            settingsStore.isReminderEnabled = false
            await notificationScheduler.cancelDailyReminder()
            return
        }

        guard await ensureNotificationAuthorization() else { return }
        isReminderEnabled = true
        settingsStore.isReminderEnabled = true
        await scheduleReminder()
    }

    func setReminderTime(_ time: Date) async {
        reminderTime = time
        settingsStore.reminderTime = time

        guard isReminderEnabled, await ensureNotificationAuthorization() else { return }
        await scheduleReminder()
    }

    func requestHealthPermission() async {
        dataState = .loading

        do {
            try await stepDataProvider.requestAuthorization()
            settingsStore.hasRequestedHealthAccess = true
            try await startObservingChangesIfNeeded()
            await refresh()
        } catch {
            dataState = state(for: error)
        }
    }

    func requestNotificationPermission() async {
        notificationAuthorizationStatus = await notificationScheduler.requestAuthorization()
    }

    func fetchTodaySteps() {
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func loadWeeklyData() {
        Task { [weak self] in
            await self?.refresh()
        }
    }

    func statisticsHistory(
        forWeekContaining date: Date,
        weeksToDisplay: Int = 8
    ) async throws -> StepStatisticsHistory {
        let selectedWeek = try week(containing: date)
        guard let today = calendar.dateInterval(of: .day, for: now()), selectedWeek.start <= today.start else {
            throw StepDataProviderError.invalidDateRange
        }

        let ranges = try (0..<max(weeksToDisplay, 1)).reversed().map { offset in
            guard let dateInWeek = calendar.date(byAdding: .weekOfYear, value: -offset, to: selectedWeek.start) else {
                throw StepDataProviderError.invalidDateRange
            }
            let week = try week(containing: dateInWeek)
            return week.start..<min(week.end, today.end)
        }
        let weeks = try await loadStatisticsWeeks(in: ranges)
        let summaries = try weeks.map { days in
            guard let summary = StatsCalculator.weeklySummary(for: days, calendar: calendar) else {
                throw StepDataProviderError.invalidDateRange
            }
            return summary
        }

        return StepStatisticsHistory(
            selectedWeekStart: selectedWeek.start,
            dailySteps: weeks.last ?? [],
            weeklySummaries: summaries
        )
    }

    private func loadWeek(containing date: Date) async throws -> [DailyStep] {
        guard let today = calendar.dateInterval(of: .day, for: date),
              let firstDate = calendar.date(byAdding: .day, value: 1 - Self.weeklyDayCount, to: today.start) else {
            throw StepDataProviderError.invalidDateRange
        }
        let range = calendar.startOfDay(for: firstDate)..<today.end
        let totals = try await stepDataProvider.steps(in: range)
        try Task.checkCancellation()
        return try dailySteps(in: range, totals: totals)
    }

    private func loadStatisticsWeeks(in ranges: [Range<Date>]) async throws -> [[DailyStep]] {
        try Task.checkCancellation()
        let cachedWeeks = ranges.map { range -> [DailyStep]? in
            guard let cached = statisticsWeekCache[range.lowerBound], cached.end == range.upperBound else {
                return nil
            }
            return cached.days
        }
        let missingRanges = zip(ranges, cachedWeeks).compactMap { range, cached in
            cached == nil ? range : nil
        }
        guard let firstMissing = missingRanges.first, let lastMissing = missingRanges.last else {
            return cachedWeeks.compactMap { $0 }
        }

        let cacheGeneration = refreshID
        let totals = try await stepDataProvider.steps(in: firstMissing.lowerBound..<lastMissing.upperBound)
        try Task.checkCancellation()
        let weeks = try zip(ranges, cachedWeeks).map { range, cached in
            if let cached { return cached }
            return try dailySteps(in: range, totals: totals)
        }
        if cacheGeneration == refreshID {
            for (index, range) in ranges.enumerated() where cachedWeeks[index] == nil {
                if let cached = statisticsWeekCache[range.lowerBound], cached.end > range.upperBound { continue }
                statisticsWeekCache[range.lowerBound] = (range.upperBound, weeks[index])
            }
        }
        return weeks
    }

    private func dailySteps(in range: Range<Date>, totals: [Date: Int]) throws -> [DailyStep] {
        var result: [DailyStep] = []
        var day = range.lowerBound
        while day < range.upperBound {
            result.append(DailyStep(date: day, steps: totals[day] ?? 0, calendar: calendar))
            guard let nextDay = calendar.dateInterval(of: .day, for: day)?.end else {
                throw StepDataProviderError.invalidDateRange
            }
            day = nextDay
        }
        return result
    }

    private func week(containing date: Date) throws -> DateInterval {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else {
            throw StepDataProviderError.invalidDateRange
        }
        return interval
    }

    private func initializeDashboard() async {
        notificationAuthorizationStatus = await notificationScheduler.authorizationStatus()
        if isReminderEnabled && !notificationAuthorizationStatus.canScheduleNotifications {
            isReminderEnabled = false
            settingsStore.isReminderEnabled = false
        }
        guard !stepDataProvider.requiresHealthAuthorization || settingsStore.hasRequestedHealthAccess else { return }
        do {
            try await startObservingChangesIfNeeded()
            await refresh()
        } catch {
            dataState = state(for: error)
        }
    }

    private func startObservingChangesIfNeeded() async throws {
        guard !hasStartedObserving else { return }
        try await stepDataProvider.startObservingChanges { [weak self] in
            await self?.refresh()
        }
        hasStartedObserving = true
    }

    private func ensureNotificationAuthorization() async -> Bool {
        let status = await notificationScheduler.authorizationStatus()
        if status == .notDetermined {
            await requestNotificationPermission()
        } else {
            notificationAuthorizationStatus = status
        }

        guard notificationAuthorizationStatus.canScheduleNotifications else {
            isReminderEnabled = false
            settingsStore.isReminderEnabled = false
            return false
        }
        return true
    }

    private func scheduleReminder() async {
        do {
            try await notificationScheduler.scheduleDailyReminder(at: reminderTime)
        } catch {
            isReminderEnabled = false
            settingsStore.isReminderEnabled = false
        }
    }

    private func notifyGoalAchievementIfNeeded(for day: Date) async {
        guard todaySteps >= goalSteps else { return }
        guard !hasNotifiedGoal(on: day) else { return }

        do {
            try await notificationScheduler.scheduleGoalAchievedNotification()
            settingsStore.lastGoalNotificationDay = day
        } catch {
            return
        }
    }

    private func hasNotifiedGoal(on day: Date) -> Bool {
        guard let lastDay = settingsStore.lastGoalNotificationDay else { return false }
        return calendar.isDate(lastDay, inSameDayAs: day)
    }

    private func persistValidatedGoal() {
        let validatedGoal = Self.validGoal(goalSteps)
        guard goalSteps != validatedGoal else {
            settingsStore.goalSteps = validatedGoal
            return
        }
        goalSteps = validatedGoal
    }

    private func state(for error: Error) -> StepDashboardState {
        guard let error = error as? StepDataProviderError else {
            return .failed(error.localizedDescription)
        }

        switch error {
        case .healthDataUnavailable:
            return .unavailable
        case .authorizationFailed:
            return .needsHealthPermission
        case .stepTypeUnavailable, .invalidDateRange, .queryFailed:
            return .failed(error.localizedDescription)
        }
    }

    private static func validGoal(_ goal: Int) -> Int {
        min(max(goal, 1), 100_000)
    }
}
