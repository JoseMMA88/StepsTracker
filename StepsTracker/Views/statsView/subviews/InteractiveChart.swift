import Charts
import SwiftUI

struct InteractiveChart: View {
    let dailySteps: [DailyStep]
    let goal: Int
    @Binding var selectedDate: Date?

    private var selectedEntry: DailyStep? {
        guard let selectedDate else { return nil }
        return dailySteps.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var accessibilitySummary: String {
        dailySteps
            .map { "\($0.date.formatted(.dateTime.weekday(.wide))): \($0.steps.formatted()) steps" }
            .joined(separator: ". ")
    }

    var body: some View {
        Chart(dailySteps, id: \.date) { entry in
            BarMark(
                x: .value("Day", entry.date, unit: .day),
                y: .value("Steps", entry.steps)
            )
            .foregroundStyle(barColor(for: entry))
            .clipShape(.rect(cornerRadius: 5))

            RuleMark(y: .value("Daily goal", goal))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let steps = value.as(Int.self) {
                        Text(steps, format: .number.notation(.compactName))
                    }
                }
            }
        }
        .frame(height: 260)
        .accessibilityLabel("Weekly steps chart")
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint("Choose a day below to hear its activity details.")
        .animation(.snappy, value: selectedEntry?.date)
    }

    private func barColor(for entry: DailyStep) -> Color {
        guard let selectedDate else { return entry.steps >= goal ? .green : .accentColor }
        return Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
            ? .accentColor
            : .secondary.opacity(0.5)
    }
}

struct WeeklyAverageChart: View {
    let summaries: [WeeklyStepSummary]
    @Binding var selectedWeekStart: Date?

    private var accessibilitySummary: String {
        summaries
            .map {
                "\($0.weekStart.formatted(.dateTime.month(.abbreviated).day())): \($0.averageDailySteps.formatted()) steps per day"
            }
            .joined(separator: ". ")
    }

    var body: some View {
        Chart(summaries, id: \.weekStart) { summary in
            LineMark(
                x: .value("Week", summary.weekStart, unit: .weekOfYear),
                y: .value("Daily average", summary.averageDailySteps)
            )
            .foregroundStyle(Color.accentColor)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Week", summary.weekStart, unit: .weekOfYear),
                y: .value("Daily average", summary.averageDailySteps)
            )
            .foregroundStyle(pointColor(for: summary))
            .symbolSize(selectedWeekStart == summary.weekStart ? 90 : 45)
        }
        .chartXSelection(value: $selectedWeekStart)
        .chartXAxis {
            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel(format: .dateTime.month(.narrow).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(.quaternary)
                AxisValueLabel {
                    if let steps = value.as(Int.self) {
                        Text(steps, format: .number.notation(.compactName))
                    }
                }
            }
        }
        .frame(height: 230)
        .accessibilityLabel("Weekly daily average chart")
        .accessibilityValue(accessibilitySummary)
        .accessibilityHint("Each point shows the average steps per day for one week.")
        .animation(.snappy, value: selectedWeekStart)
    }

    private func pointColor(for summary: WeeklyStepSummary) -> Color {
        guard let selectedWeekStart else { return .accentColor }
        return Calendar.current.isDate(summary.weekStart, inSameDayAs: selectedWeekStart)
            ? .accentColor
            : .secondary
    }
}
