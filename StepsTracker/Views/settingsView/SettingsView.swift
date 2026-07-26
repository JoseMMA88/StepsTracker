import SwiftUI
import UserNotifications
import UIKit

struct SettingsView: View {
    @Environment(StepModel.self) private var stepModel

    var body: some View {
        NavigationStack {
            Form {
                GoalsSectionView()
                ReminderSectionView()
                if stepModel.isUsingDemoData {
                    DemoDataSectionView()
                }
                PrivacySectionView()
                InformationSectionView()
                AboutSectionView()
            }
            .navigationTitle("Settings")
        }
    }
}

private struct DemoDataSectionView: View {
    var body: some View {
        Section("Development") {
            Label("Demo data is active", systemImage: "wrench.and.screwdriver.fill")
                .foregroundStyle(.orange)
            Text("This build uses sample steps so you can explore the app without Health access.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ReminderSectionView: View {
    @Environment(StepModel.self) private var stepModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle("Daily reminder", isOn: reminderEnabledBinding)

            if stepModel.isReminderEnabled {
                DatePicker(
                    "Reminder time",
                    selection: reminderTimeBinding,
                    displayedComponents: .hourAndMinute
                )
            }

            notificationPermissionStatus
        } header: {
            Text("Reminders")
        } footer: {
            Text("Reminders are optional. Choose a time that supports your routine.")
        }
    }

    @ViewBuilder
    private var notificationPermissionStatus: some View {
        switch stepModel.notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            Label("Notifications allowed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .notDetermined:
            Button("Allow notifications") {
                Task {
                    await stepModel.requestNotificationPermission()
                }
            }
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications are turned off", systemImage: "bell.slash")
                    .foregroundStyle(.secondary)
                Button("Open notification settings") {
                    openURL(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        case .unavailable:
            Label("Notifications are unavailable on this device", systemImage: "bell.slash")
                .foregroundStyle(.secondary)
        @unknown default:
            EmptyView()
        }
    }

    private var reminderEnabledBinding: Binding<Bool> {
        Binding(
            get: { stepModel.isReminderEnabled },
            set: { isEnabled in
                Task {
                    await stepModel.setReminderEnabled(isEnabled)
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: { stepModel.reminderTime },
            set: { time in
                Task {
                    await stepModel.setReminderTime(time)
                }
            }
        )
    }
}
