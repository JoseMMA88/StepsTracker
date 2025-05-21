import Foundation
import CoreMotion
import HealthKit

class StepModel: ObservableObject {
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    
    @Published var todaySteps: Int = 0
    @Published var goalSteps: Int = 10000
    @Published var weeklySteps: [Date: Int] = [:]
    @Published var isUpdating = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        if CMPedometer.isStepCountingAvailable() {
            startUpdatingSteps()
        } else {
            print("Step counting is not available on this device")
        }
    }
    
    public func progress() -> Double {
        return min(Double(todaySteps) / Double(goalSteps), 1.0)
    }
    
    private func requestHealthKitPermission() {
        // Check if HealthKit is available
        if HKHealthStore.isHealthDataAvailable() {
            // Define the data types we want to read
            let types = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
            
            // Request authorization
            healthStore.requestAuthorization(toShare: nil, read: types) { [weak self] success, error in
                if success {
                    DispatchQueue.main.async {
                        self?.startUpdatingSteps()
                    }
                } else {
                    if let error = error {
                        print("Error requesting HealthKit permission: \(error.localizedDescription)")
                    }
                    // Use pedometer as fallback
                    self?.checkPedometerAvailability()
                }
            }
        } else {
            // HealthKit not available, use pedometer
            checkPedometerAvailability()
        }
    }
    
    private func checkPedometerAvailability() {
        if CMPedometer.isStepCountingAvailable() {
            startUpdatingWithPedometer()
        } else {
            print("Step counting is not available on this device")
        }
    }
    
    private func startUpdatingSteps() {
        isUpdating = true
        
        // Configure HealthKit query for today's steps
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Define step count data type
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Configure observer for real-time updates
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] query, completionHandler, error in
            self?.fetchTodaySteps()
            completionHandler()
        }
        
        healthStore.execute(query)
        
        // Enable background updates (optional)
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { success, error in
            if let error = error {
                print("Error enabling background updates: \(error.localizedDescription)")
            }
        }
        
        // Get initial steps
        fetchTodaySteps()
        
        // Load weekly data
        loadWeeklyData()
    }
    
    private func fetchTodaySteps() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Predicate to get steps only for today
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // Statistics query
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error getting steps from HealthKit: \(error.localizedDescription)")
                }
                return
            }
            
            // Convert to steps (integers)
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            DispatchQueue.main.async {
                self?.todaySteps = steps
                
                // Also update today's steps in weekly record
                if let startOfDay = calendar.startOfDay(for: now) as NSDate? {
                    self?.weeklySteps[startOfDay as Date] = steps
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func startUpdatingWithPedometer() {
        // Original method using pedometer as fallback
        isUpdating = true
        
        let calendar = Calendar.current
        if let startOfDay = calendar.startOfDay(for: Date()) as NSDate? {
            pedometer.startUpdates(from: startOfDay as Date) { [weak self] data, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let data = data {
                        self.todaySteps = data.numberOfSteps.intValue
                    } else if let error = error {
                        print("Error counting steps: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        loadWeeklyData()
    }
    
    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  let startOfDay = calendar.startOfDay(for: date) as NSDate?,
                  let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay as Date) as NSDate? else {
                continue
            }
            
            // Predicate to get steps only for this day
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay as Date,
                end: endOfDay as Date,
                options: .strictStartDate
            )
            
            // Statistics query
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error = error {
                        print("Error getting weekly steps: \(error.localizedDescription)")
                    }
                    return
                }
                
                // Convert to steps (integers)
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                
                DispatchQueue.main.async {
                    self?.weeklySteps[startOfDay as Date] = steps
                }
            }
            
            healthStore.execute(query)
        }
    }
}

