import Foundation
import HealthKit

struct DailyStep: Identifiable, Hashable, Sendable {
    let date: Date
    let steps: Int

    var id: Date { date }

    init(date: Date, steps: Int) {
        self.date = Calendar.autoupdatingCurrent.startOfDay(for: date)
        self.steps = max(steps, 0)
    }
}

enum StepDataProviderError: Error, Equatable, LocalizedError {
    case healthDataUnavailable
    case authorizationFailed
    case stepTypeUnavailable
    case invalidDateRange
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Health data is unavailable on this device."
        case .authorizationFailed:
            return "Health data authorization was not granted."
        case .stepTypeUnavailable:
            return "Step count data is unavailable."
        case .invalidDateRange:
            return "The requested day could not be calculated."
        case .queryFailed(let message):
            return message
        }
    }
}

@MainActor
protocol StepDataProviding: AnyObject {
    var requiresHealthAuthorization: Bool { get }
    func requestAuthorization() async throws
    func steps(for day: Date) async throws -> Int
    func startObservingChanges(onUpdate: @escaping @Sendable @MainActor () async -> Void) async throws
}

extension StepDataProviding {
    var requiresHealthAuthorization: Bool { true }
}

@MainActor
final class HealthKitStepDataProvider: StepDataProviding {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(healthStore: HKHealthStore = HKHealthStore(), calendar: Calendar = .autoupdatingCurrent) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw StepDataProviderError.healthDataUnavailable
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            throw StepDataProviderError.stepTypeUnavailable
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
                if let error {
                    continuation.resume(throwing: StepDataProviderError.queryFailed(error.localizedDescription))
                    return
                }
                guard success else {
                    continuation.resume(throwing: StepDataProviderError.authorizationFailed)
                    return
                }
                continuation.resume()
            }
        }
    }

    func steps(for day: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw StepDataProviderError.stepTypeUnavailable
        }

        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            throw StepDataProviderError.invalidDateRange
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error {
                    continuation.resume(throwing: StepDataProviderError.queryFailed(error.localizedDescription))
                    return
                }
                let value = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: max(Int(value), 0))
            }
            healthStore.execute(query)
        }
    }

    func startObservingChanges(onUpdate: @escaping @Sendable @MainActor () async -> Void) async throws {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw StepDataProviderError.stepTypeUnavailable
        }

        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completion, error in
            guard error == nil else {
                completion()
                return
            }

            Task { @MainActor in
                await onUpdate()
                completion()
            }
        }
        healthStore.execute(query)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
                if let error {
                    continuation.resume(throwing: StepDataProviderError.queryFailed(error.localizedDescription))
                    return
                }
                guard success else {
                    continuation.resume(throwing: StepDataProviderError.queryFailed("Unable to enable HealthKit background delivery."))
                    return
                }
                continuation.resume()
            }
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
@MainActor
final class DemoStepDataProvider: StepDataProviding {
    private static let weeklyBaselines = [6_900, 7_500, 8_100, 7_700, 8_950, 8_200, 9_100, 8_500]
    private static let weekdayOffsets = [-50, -1_300, 500, 1_200, 250, -750, 1_000]

    private let calendar: Calendar
    private let now: @MainActor () -> Date

    var requiresHealthAuthorization: Bool { false }

    init(
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping @MainActor () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.now = now
    }

    func requestAuthorization() async throws {}

    func steps(for day: Date) async throws -> Int {
        let today = calendar.startOfDay(for: now())
        let requestedDay = calendar.startOfDay(for: day)
        guard requestedDay <= today,
              let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today),
              let requestedWeek = calendar.dateInterval(of: .weekOfYear, for: requestedDay) else {
            return 0
        }

        let daysBetweenWeeks = calendar.dateComponents(
            [.day],
            from: requestedWeek.start,
            to: currentWeek.start
        ).day ?? 0
        let weeksAgo = max(daysBetweenWeeks / 7, 0)
        let baselineIndex = Self.weeklyBaselines.count - 1 - (weeksAgo % Self.weeklyBaselines.count)
        let weekdayIndex = calendar.component(.weekday, from: requestedDay) - 1

        return max(Self.weeklyBaselines[baselineIndex] + Self.weekdayOffsets[weekdayIndex], 0)
    }

    func startObservingChanges(onUpdate: @escaping @Sendable @MainActor () async -> Void) async throws {}
}
#endif
