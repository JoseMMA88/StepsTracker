import Foundation
import HealthKit

/// Abstraction to fetch steps for a given day, to enable testing.
protocol StepDataProviding {
    /// Returns the total number of steps for the provided calendar day.
    func stepsForDay(_ date: Date, completion: @escaping (Int) -> Void)
}

/// HealthKit-backed implementation of StepDataProviding.
final class HealthKitStepDataProvider: StepDataProviding {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }

    func stepsForDay(_ date: Date, completion: @escaping (Int) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion(0)
            return
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            completion(Int(steps))
        }

        healthStore.execute(query)
    }
}


