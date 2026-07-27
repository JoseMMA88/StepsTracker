import SwiftUI

struct StatsDashboard: View {
    let dailySteps: [DailyStep]
    let weeklySummaries: [WeeklyStepSummary]
    let goal: Int
    let weekStart: Date
    let isLoading: Bool
    let canNavigateForward: Bool
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void
    let onCurrentWeek: () -> Void
    @State private var selectedDate: Date?
    @State private var selectedAverageWeek: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedEntry: DailyStep? {
        ChartSelectionResolver.dailyEntry(for: selectedDate, in: dailySteps)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                WeekNavigator(
                    weekStart: weekStart,
                    isLoading: isLoading,
                    canNavigateForward: canNavigateForward,
                    onPreviousWeek: onPreviousWeek,
                    onNextWeek: onNextWeek,
                    onCurrentWeek: onCurrentWeek
                )

                ChartSection(title: "Daily steps") {
                    VStack(alignment: .leading, spacing: 14) {
                        InteractiveChart(
                            dailySteps: dailySteps,
                            goal: goal,
                            weekStart: weekStart,
                            selectedDate: $selectedDate
                        )

                        DaySelector(
                            dailySteps: dailySteps,
                            selectedDate: $selectedDate
                        )

                        Group {
                            if let selectedEntry {
                                SelectionCard(
                                    entry: selectedEntry,
                                    goal: goal,
                                    onClear: { selectedDate = nil }
                                )
                                .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .animation(reduceMotion ? nil : .snappy, value: selectedEntry?.id)
                    }
                }

                StatsSummary(dailySteps: dailySteps)

                ChartSection(title: "Daily average by week") {
                    WeeklyAverageChart(
                        summaries: weeklySummaries,
                        selectedWeekStart: $selectedAverageWeek
                    )
                }
            }
            .frame(maxWidth: 720)
            .padding()
            .frame(maxWidth: .infinity)
        }
        .onChange(of: dailySteps) { _, _ in
            selectedDate = nil
        }
        .onChange(of: weeklySummaries) { _, _ in
            selectedAverageWeek = nil
        }
        .onChange(of: weekStart) { _, _ in
            selectedDate = nil
            selectedAverageWeek = nil
        }
    }
}

private struct WeekNavigator: View {
    let weekStart: Date
    let isLoading: Bool
    let canNavigateForward: Bool
    let onPreviousWeek: () -> Void
    let onNextWeek: () -> Void
    let onCurrentWeek: () -> Void

    private var weekEnd: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
    }

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onPreviousWeek) {
                Label("Previous week", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
            .disabled(isLoading)
            .accessibilityLabel("Previous week")

            Spacer(minLength: 0)

            VStack(spacing: 4) {
                Text(weekStart, format: .dateTime.month(.abbreviated).day())
                    .font(.headline)
                Text(weekEnd, format: .dateTime.month(.abbreviated).day())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("This week", action: onCurrentWeek)
                    .font(.caption.weight(.semibold))
                    .disabled(isLoading || !canNavigateForward)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selected week")
            .accessibilityValue("\(weekStart.formatted(.dateTime.month(.wide).day())) to \(weekEnd.formatted(.dateTime.month(.wide).day()))")

            Spacer(minLength: 0)

            Button(action: onNextWeek) {
                Label("Next week", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
            }
            .disabled(isLoading || !canNavigateForward)
            .accessibilityLabel("Next week")
        }
        .overlay(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .offset(y: 20)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ChartSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 20))
        .shadow(color: .primary.opacity(0.06), radius: 10, y: 5)
    }
}

struct StatsSummary: View {
    let dailySteps: [DailyStep]

    private var totalSteps: Int {
        StatsCalculator.totalWeeklySteps(dailySteps: dailySteps)
    }

    private var averageSteps: Int {
        StatsCalculator.averageDailySteps(dailySteps: dailySteps)
    }

    private var bestDaySteps: Int {
        StatsCalculator.bestDaySteps(dailySteps: dailySteps)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                summaryCards
            }

            VStack(spacing: 12) {
                summaryCards
            }
        }
    }

    @ViewBuilder
    private var summaryCards: some View {
        StatisticCard(title: "Daily average", value: averageSteps, icon: "figure.walk")
        StatisticCard(title: "Weekly total", value: totalSteps, icon: "sum")
        StatisticCard(title: "Best day", value: bestDaySteps, icon: "star.fill")
    }
}

private struct DaySelector: View {
    let dailySteps: [DailyStep]
    @Binding var selectedDate: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectedEntry: DailyStep? {
        ChartSelectionResolver.dailyEntry(for: selectedDate, in: dailySteps)
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(dailySteps) { entry in
                    dayButton(for: entry)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel("Selected day")
    }

    private func dayButton(for entry: DailyStep) -> some View {
        let isSelected = selectedEntry?.id == entry.id

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                selectedDate = isSelected ? nil : entry.date
            }
        } label: {
            VStack(spacing: 3) {
                Text(entry.date, format: .dateTime.weekday(.narrow))
                    .font(.caption.weight(.semibold))

                Text(entry.date, format: .dateTime.day())
                    .font(.headline)
                    .monospacedDigit()

                Text(entry.steps, format: .number.notation(.compactName))
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                    .monospacedDigit()
            }
            .foregroundStyle(isSelected ? Color.white : .primary)
            .frame(minWidth: 50, minHeight: 54)
            .padding(.horizontal, 4)
            .background(
                isSelected ? Color.accentColor : Color.secondary.opacity(0.1),
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                if !isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityValue(String(localized: "\(entry.steps) steps"))
        .accessibilityHint(isSelected ? "Tap the same day to deselect" : "Select day")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct StatisticCard: View {
    let title: LocalizedStringKey
    let value: Int
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)

            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .monospacedDigit()

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 16))
        .shadow(color: .primary.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
    }
}
