import SwiftUI

struct StatsView: View {
    @Environment(StepModel.self) private var stepModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Statistics")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await stepModel.refresh() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(stepModel.isUpdating)
                    }
                }
                .task {
                    guard stepModel.dataState != .needsHealthPermission else { return }
                    await stepModel.refresh()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch stepModel.dataState {
        case .loading:
            ProgressView("Loading statistics")
        case .needsHealthPermission:
            ContentUnavailableView {
                Label("Allow access to see your week", systemImage: "heart.text.square")
            } description: {
                Text("Health access is needed to show your activity history.")
            } actions: {
                Button("Allow Health access") {
                    Task { await stepModel.requestHealthPermission() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .unavailable:
            ContentUnavailableView(
                "Statistics unavailable",
                systemImage: "chart.bar.xaxis",
                description: Text("This device cannot provide step data.")
            )
        case .failed(let message):
            ContentUnavailableView {
                Label("Unable to load statistics", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") {
                    Task { await stepModel.refresh() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .ready:
            StatisticsHistoryView(stepModel: stepModel)
        }
    }
}

private struct StatisticsHistoryView: View {
    let stepModel: StepModel

    @State private var selectedWeek = Calendar.autoupdatingCurrent.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    @State private var history: StepStatisticsHistory?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var calendar: Calendar { .autoupdatingCurrent }

    private var currentWeekStart: Date {
        calendar.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    var body: some View {
        Group {
            if let history {
                StatsDashboard(
                    dailySteps: history.dailySteps,
                    weeklySummaries: history.weeklySummaries,
                    goal: stepModel.goalSteps,
                    weekStart: history.selectedWeekStart,
                    isLoading: isLoading,
                    canNavigateForward: selectedWeek < currentWeekStart,
                    onPreviousWeek: showPreviousWeek,
                    onNextWeek: showNextWeek,
                    onCurrentWeek: showCurrentWeek
                )
            } else if isLoading {
                ProgressView("Loading statistics")
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Unable to load statistics", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try again") {
                        Task { await loadHistory() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task(id: selectedWeek) {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        let requestedWeek = selectedWeek
        isLoading = true
        errorMessage = nil

        do {
            let loadedHistory = try await stepModel.statisticsHistory(forWeekContaining: requestedWeek)
            guard !Task.isCancelled, selectedWeek == requestedWeek else { return }
            history = loadedHistory
            isLoading = false
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled, selectedWeek == requestedWeek else { return }
            errorMessage = error.localizedDescription
            isLoading = false
            if let history {
                selectedWeek = history.selectedWeekStart
            }
        }
    }

    private func showPreviousWeek() {
        guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) else { return }
        selectedWeek = previousWeek
    }

    private func showNextWeek() {
        guard selectedWeek < currentWeekStart,
              let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) else { return }
        selectedWeek = min(nextWeek, currentWeekStart)
    }

    private func showCurrentWeek() {
        selectedWeek = currentWeekStart
    }
}
