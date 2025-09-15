import Foundation
import CoreMotion
import HealthKit

class StepModel: ObservableObject {
    
    // MARK: - Properties
    private let pedometer = CMPedometer()
    private let healthStore = HKHealthStore()
    private let notificationManager = NotificationManager.shared
    private let stepDataProvider: StepDataProviding
    
    @Published var todaySteps: Int = 0
    @Published var goalSteps: Int = 10000
    @Published var weeklySteps: [Date: Int] = [:]
    @Published var isUpdating = false
    
    
    
    // MARK: - Initializer
    init(enableSideEffects: Bool = true, stepDataProvider: StepDataProviding? = nil) {
        self.stepDataProvider = stepDataProvider ?? HealthKitStepDataProvider(healthStore: healthStore)
        if enableSideEffects {
            requestHealthKitPermission()
            notificationManager.requestAuthorization()
            notificationManager.scheduleDailyReminder()
        }
    }
    
    // MARK: - Functions
    private func checkAuthorizationStatus() {
        if CMPedometer.isStepCountingAvailable() {
            startUpdatingSteps()
        } else {
            print("Step counting is not available on this device")
        }
    }
    
    public func progress() -> Double {
        guard goalSteps > 0, todaySteps >= 0 else { return 0.0 }
        let progress = Double(todaySteps) / Double(goalSteps)
        return progress.isFinite ? min(progress, 1.0) : 0.0
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
    
    public func fetchTodaySteps() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        stepDataProvider.stepsForDay(startOfDay) { [weak self] steps in
            DispatchQueue.main.async {
                let oldSteps = self?.todaySteps ?? 0
                self?.todaySteps = steps
                if oldSteps < (self?.goalSteps ?? 0) && steps >= (self?.goalSteps ?? 0) {
                    self?.notificationManager.scheduleGoalAchievedNotification()
                }
                
                let weeklyData = [
                    Calendar.current.date(byAdding: .day, value: -6, to: Date())!: 7200,
                    Calendar.current.date(byAdding: .day, value: -5, to: Date())!: 9800,
                    Calendar.current.date(byAdding: .day, value: -4, to: Date())!: 11200,
                    Calendar.current.date(byAdding: .day, value: -3, to: Date())!: 8900,
                    Calendar.current.date(byAdding: .day, value: -2, to: Date())!: 15300,
                    Calendar.current.date(byAdding: .day, value: -1, to: Date())!: 6800,
                    Date(): 8750
                ]
                
                self?.weeklySteps = weeklyData
            }
        }
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
    
    public func loadWeeklyData() {
        let calendar = Calendar.current
        let today = Date()
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            stepDataProvider.stepsForDay(startOfDay) { [weak self] steps in
                DispatchQueue.main.async {
                    self?.weeklySteps[startOfDay] = steps
                }
            }
        }
    }
}

