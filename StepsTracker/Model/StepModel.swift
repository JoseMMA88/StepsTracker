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
    
    func checkAuthorizationStatus() {
        if CMPedometer.isStepCountingAvailable() {
            startUpdatingSteps()
        } else {
            print("El conteo de pasos no está disponible en este dispositivo")
        }
    }
    
    func progress() -> Double {
        return min(Double(todaySteps) / Double(goalSteps), 1.0)
    }
    
    func requestHealthKitPermission() {
        // Comprobar si HealthKit está disponible
        if HKHealthStore.isHealthDataAvailable() {
            // Definir los tipos de datos que queremos leer
            let types = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
            
            // Solicitar autorización
            healthStore.requestAuthorization(toShare: nil, read: types) { [weak self] success, error in
                if success {
                    DispatchQueue.main.async {
                        self?.startUpdatingSteps()
                    }
                } else {
                    if let error = error {
                        print("Error al solicitar permiso HealthKit: \(error.localizedDescription)")
                    }
                    // Usar pedómetro como respaldo
                    self?.checkPedometerAvailability()
                }
            }
        } else {
            // HealthKit no disponible, usar pedómetro
            checkPedometerAvailability()
        }
    }
    
    func checkPedometerAvailability() {
        if CMPedometer.isStepCountingAvailable() {
            startUpdatingWithPedometer()
        } else {
            print("El conteo de pasos no está disponible en este dispositivo")
        }
    }
    
    func startUpdatingSteps() {
        isUpdating = true
        
        // Configurar consulta de HealthKit para pasos de hoy
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        // Definir el tipo de datos para pasos
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Configurar observador para actualizaciones en tiempo real
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] query, completionHandler, error in
            self?.fetchTodaySteps()
            completionHandler()
        }
        
        healthStore.execute(query)
        
        // También habilitar actualizaciones en segundo plano (opcional)
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { success, error in
            if let error = error {
                print("Error al habilitar actualizaciones en segundo plano: \(error.localizedDescription)")
            }
        }
        
        // Obtener pasos iniciales
        fetchTodaySteps()
        
        // Cargar datos de la semana
        loadWeeklyData()
    }
    
    func fetchTodaySteps() {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        // Predicado para obtener pasos solo de hoy
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        // Consulta de estadísticas
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error al obtener pasos de HealthKit: \(error.localizedDescription)")
                }
                return
            }
            
            // Convertir a pasos (enteros)
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            DispatchQueue.main.async {
                self?.todaySteps = steps
                
                // Actualizar también los pasos de hoy en el registro semanal
                if let startOfDay = calendar.startOfDay(for: now) as NSDate? {
                    self?.weeklySteps[startOfDay as Date] = steps
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    func startUpdatingWithPedometer() {
        // El método original utilizando pedómetro como respaldo
        isUpdating = true
        
        let calendar = Calendar.current
        if let startOfDay = calendar.startOfDay(for: Date()) as NSDate? {
            pedometer.startUpdates(from: startOfDay as Date) { [weak self] data, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let data = data {
                        self.todaySteps = data.numberOfSteps.intValue
                    } else if let error = error {
                        print("Error al contar pasos: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        loadWeeklyData()
    }
    
    func loadWeeklyData() {
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
            
            // Predicado para obtener pasos solo de este día
            let predicate = HKQuery.predicateForSamples(
                withStart: startOfDay as Date,
                end: endOfDay as Date,
                options: .strictStartDate
            )
            
            // Consulta de estadísticas
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error = error {
                        print("Error al obtener pasos semanales: \(error.localizedDescription)")
                    }
                    return
                }
                
                // Convertir a pasos (enteros)
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                
                DispatchQueue.main.async {
                    self?.weeklySteps[startOfDay as Date] = steps
                }
            }
            
            healthStore.execute(query)
        }
    }
}

