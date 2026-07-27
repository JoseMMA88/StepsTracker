import SwiftUI

struct MainView: View {
    @Environment(StepModel.self) private var stepModel

    var body: some View {
        NavigationStack {
            dashboard
                .navigationTitle("Today")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        refreshButton
                    }
                }
                .task {
                    guard stepModel.dataState != .needsHealthPermission else { return }
                    await stepModel.refresh()
                }
        }
    }

    @ViewBuilder
    private var dashboard: some View {
        switch stepModel.dataState {
        case .loading:
            DashboardLoadingView()
        case .needsHealthPermission:
            PermissionRequiredView {
                await stepModel.requestHealthPermission()
            }
        case .unavailable:
            ContentUnavailableView(
                "Step tracking is unavailable",
                systemImage: "figure.walk",
                description: Text("This device cannot provide step data.")
            )
        case .failed(let message):
            DashboardErrorView(message: message) {
                await stepModel.refresh()
            }
        case .ready:
            if stepModel.todaySteps == 0 {
                EmptyStepsView(
                    isRefreshing: stepModel.isUpdating,
                    onRefresh: { await stepModel.refresh() }
                )
            } else {
                DashboardContent(
                    steps: stepModel.todaySteps,
                    goal: stepModel.goalSteps,
                    isRefreshing: stepModel.isUpdating,
                    onRefresh: { await stepModel.refresh() }
                )
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task {
                await stepModel.refresh()
            }
        } label: {
            if stepModel.isUpdating {
                ProgressView()
            } else {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
        .disabled(stepModel.isUpdating)
        .accessibilityLabel("Refresh steps")
    }
}

private struct DashboardContent: View {
    let steps: Int
    let goal: Int
    let isRefreshing: Bool
    let onRefresh: () async -> Void

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(max(Double(steps) / Double(goal), 0), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TodayHeader()

                StepProgressCard(
                    steps: steps,
                    goal: goal,
                    progress: progress
                )

                DailyGoalView(steps: steps, goal: goal)
            }
            .frame(maxWidth: 620)
            .padding(.horizontal)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await onRefresh()
        }
        .overlay(alignment: .top) {
            if isRefreshing {
                ProgressView()
                    .padding(.top, 8)
            }
        }
    }
}

private struct TodayHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline)
            Text("Your activity today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StepProgressCard: View {
    let steps: Int
    let goal: Int
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var hasReachedGoal: Bool {
        steps >= goal
    }

    private var accessibilitySummary: String {
        let percentage = Int((progress * 100).rounded())
        return "\(steps.formatted()) steps. \(percentage)% of your \(goal.formatted()) step goal."
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 16)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        hasReachedGoal ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .snappy, value: progress)

                StepCounterView(steps: steps, progress: progress)
            }
            .frame(width: 220, height: 220)

            Label {
                Text(hasReachedGoal ? "Daily goal achieved" : "Keep moving at your pace")
                    .font(.headline)
            } icon: {
                Image(systemName: hasReachedGoal ? "checkmark.circle.fill" : "figure.walk")
                    .foregroundStyle(hasReachedGoal ? Color.green : .accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background, in: .rect(cornerRadius: 24))
        .shadow(color: .primary.opacity(0.08), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily steps")
        .accessibilityValue(accessibilitySummary)
    }
}

private struct DashboardLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading your steps")
                .font(.headline)
            Text("This can take a moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct PermissionRequiredView: View {
    let requestPermission: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Allow access to your steps", systemImage: "heart.text.square")
        } description: {
            Text("StepsTracker reads step data from Health to show your daily progress and weekly activity. You can change this later in Settings.")
        } actions: {
            Button("Allow Health access") {
                Task {
                    await requestPermission()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

private struct EmptyStepsView: View {
    let isRefreshing: Bool
    let onRefresh: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No steps yet", systemImage: "figure.walk.motion")
        } description: {
            Text("Your steps will appear here once Health has recorded activity today.")
        } actions: {
            Button("Refresh") {
                Task {
                    await onRefresh()
                }
            }
            .disabled(isRefreshing)
        }
        .refreshable {
            await onRefresh()
        }
        .overlay {
            if isRefreshing {
                ProgressView()
            }
        }
    }
}

private struct DashboardErrorView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Unable to load steps", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try again") {
                Task {
                    await retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
