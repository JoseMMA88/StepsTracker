import Foundation
import UserNotifications

enum NotificationAuthorizationStatus: Equatable {
    case authorized
    case provisional
    case ephemeral
    case notDetermined
    case denied
    case unavailable

    var canScheduleNotifications: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied, .unavailable:
            return false
        }
    }
}

@MainActor
protocol NotificationScheduling: AnyObject {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async -> NotificationAuthorizationStatus
    func scheduleDailyReminder(at time: Date) async throws
    func cancelDailyReminder() async
    func scheduleGoalAchievedNotification() async throws
}

@MainActor
final class NotificationManager: NSObject, NotificationScheduling, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private let notificationCenter: UNUserNotificationCenter

    override convenience init() {
        self.init(notificationCenter: .current())
    }

    init(notificationCenter: UNUserNotificationCenter) {
        self.notificationCenter = notificationCenter
        super.init()
        notificationCenter.delegate = self
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                continuation.resume(returning: Self.status(from: settings.authorizationStatus))
            }
        }
    }

    func requestAuthorization() async -> NotificationAuthorizationStatus {
        await withCheckedContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if error != nil {
                    continuation.resume(returning: .unavailable)
                    return
                }
                continuation.resume(returning: granted ? .authorized : .denied)
            }
        }
    }

    func scheduleDailyReminder(at time: Date) async throws {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Stay Active! 🚶‍♂️".localized
        content.body = "Don't forget to stay active today. Every step counts towards your daily goal.".localized
        content.sound = .default

        let components = Calendar.autoupdatingCurrent.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.dailyReminderIdentifier, content: content, trigger: trigger)
        try await add(request)
    }

    func cancelDailyReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.dailyReminderIdentifier])
    }

    func scheduleGoalAchievedNotification() async throws {
        let content = UNMutableNotificationContent()
        content.title = "Goal Achieved! 🎉".localized
        content.body = "Congratulations! You've reached your daily step goal.".localized
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Self.goalAchievedIdentifier, content: content, trigger: trigger)
        try await add(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            notificationCenter.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            }
        }
    }

    nonisolated private static func status(from status: UNAuthorizationStatus) -> NotificationAuthorizationStatus {
        switch status {
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        @unknown default:
            return .unavailable
        }
    }

    private static let dailyReminderIdentifier = "dailyReminder"
    private static let goalAchievedIdentifier = "goalAchieved"
}
