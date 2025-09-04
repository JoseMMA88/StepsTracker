import Foundation
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    // MARK: - Initializer
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Functions
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    public func scheduleGoalAchievedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Goal Achieved! 🎉".localized
        content.body = "Congratulations! You've reached your daily step goal.".localized
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "goalAchieved", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    public func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Stay Active! 🚶‍♂️".localized
        content.body = "Don't forget to stay active today. Every step counts towards your daily goal.".localized
        content.sound = .default
        
        // Schedule for 10:00 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
} 
