import Charts
import SwiftUI

enum ChartSelectionResolver {
    static func dailyEntry(
        for selection: Date?,
        in entries: [DailyStep],
        calendar: Calendar = .autoupdatingCurrent
    ) -> DailyStep? {
        guard let selection else { return nil }
        if let sameDayEntry = entries.first(where: { calendar.isDate($0.date, inSameDayAs: selection) }) {
            return sameDayEntry
        }
        return entries.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(selection)) < abs(rhs.date.timeIntervalSince(selection))
        }
    }

    static func weeklySummary(
        for selection: Date?,
        in summaries: [WeeklyStepSummary]
    ) -> WeeklyStepSummary? {
        guard let selection else { return nil }
        return summaries.min { lhs, rhs in
            let lhsDistance = abs(lhs.weekStart.timeIntervalSince(selection))
            let rhsDistance = abs(rhs.weekStart.timeIntervalSince(selection))
            if lhsDistance == rhsDistance {
                return lhs.weekStart < rhs.weekStart
            }
            return lhsDistance < rhsDistance
        }
    }
}

struct InteractiveChart: View {
    let dailySteps: [DailyStep]
    let goal: Int
    let weekStart: Date
    @Binding var selectedDate: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var selectedEntry: DailyStep? {
        ChartSelectionResolver.dailyEntry(for: selectedDate, in: dailySteps)
    }

    private var yAxisMaximum: Int {
        let maximum = max(max(goal, dailySteps.map(\.steps).max() ?? 0), 1)
        return maximum + max(maximum / 5, 1)
    }

    private var weekEnd: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var weekAxisDates: [Date] {
        (0..<7).compactMap {
            Calendar.autoupdatingCurrent.date(byAdding: .day, value: $0, to: weekStart)
        }
    }

    private var accessibilitySummary: String {
        dailySteps
            .map { entry in
                let day = entry.date.formatted(.dateTime.weekday(.wide))
                let steps = String(localized: "\(entry.steps) steps")
                return "\(day): \(steps)"
            }
            .joined(separator: ". ")
    }

    private var accessibilityValue: String {
        guard let selectedEntry else { return accessibilitySummary }
        let day = selectedEntry.date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        let steps = String(localized: "\(selectedEntry.steps) steps")
        return "\(day): \(steps)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Chart {
                ForEach(dailySteps) { entry in
                    BarMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Steps", entry.steps)
                    )
                    .foregroundStyle(barColor(for: entry))
                    .clipShape(.rect(cornerRadius: 5))
                }

                RuleMark(y: .value("Daily goal", goal))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                if let selectedEntry {
                    RuleMark(x: .value("Selected day", selectedEntry.date, unit: .day))
                        .foregroundStyle(Color.accentColor.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))

                    PointMark(
                        x: .value("Selected day", selectedEntry.date, unit: .day),
                        y: .value("Steps", selectedEntry.steps)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbolSize(90)
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXScale(domain: weekStart...weekEnd)
            .chartYScale(domain: 0...yAxisMaximum)
            .chartXAxis {
                AxisMarks(values: weekAxisDates) { value in
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
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 320 : 260)
            .accessibilityLabel("Weekly steps chart")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint("Tap or drag to explore the chart")
            .sensoryFeedback(.selection, trigger: selectedEntry?.date) { oldValue, newValue in
                newValue != nil && oldValue != newValue
            }
            .animation(reduceMotion ? nil : .snappy, value: selectedEntry?.date)

            interactionHint
        }
    }

    private var interactionHint: some View {
        Label("Tap or drag to explore the chart", systemImage: "hand.draw")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }

    private func barColor(for entry: DailyStep) -> Color {
        guard let selectedEntry else { return entry.steps >= goal ? .green : .accentColor }
        return entry.id == selectedEntry.id ? .accentColor : .secondary.opacity(0.35)
    }
}

struct WeeklyAverageChart: View {
    let summaries: [WeeklyStepSummary]
    @Binding var selectedWeekStart: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var selectedSummary: WeeklyStepSummary? {
        ChartSelectionResolver.weeklySummary(for: selectedWeekStart, in: summaries)
    }

    private var yAxisMaximum: Int {
        let maximum = max(summaries.map(\.averageDailySteps).max() ?? 0, 1)
        return maximum + max(maximum / 5, 1)
    }

    private var accessibilitySummary: String {
        summaries
            .map { summary in
                let week = summary.weekStart.formatted(.dateTime.month(.abbreviated).day())
                let average = String(localized: "\(summary.averageDailySteps) steps per day")
                return "\(week): \(average)"
            }
            .joined(separator: ". ")
    }

    private var accessibilityValue: String {
        guard let selectedSummary else { return accessibilitySummary }
        let week = selectedSummary.weekStart.formatted(.dateTime.month(.wide).day())
        let average = String(localized: "\(selectedSummary.averageDailySteps) steps per day")
        return "\(week): \(average)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(summaries) { summary in
                    LineMark(
                        x: .value("Week", summary.weekStart, unit: .weekOfYear),
                        y: .value("Daily average", summary.averageDailySteps)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Week", summary.weekStart, unit: .weekOfYear),
                        y: .value("Daily average", summary.averageDailySteps)
                    )
                    .foregroundStyle(pointColor(for: summary))
                    .symbolSize(selectedSummary?.id == summary.id ? 100 : 45)
                }

                if let selectedSummary {
                    RuleMark(x: .value("Selected week", selectedSummary.weekStart, unit: .weekOfYear))
                        .foregroundStyle(Color.accentColor.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
            .chartXSelection(value: $selectedWeekStart)
            .chartYScale(domain: 0...yAxisMaximum)
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
            .frame(height: dynamicTypeSize.isAccessibilitySize ? 290 : 230)
            .accessibilityLabel("Weekly daily average chart")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint("Tap or drag to explore the chart")
            .sensoryFeedback(.selection, trigger: selectedSummary?.weekStart) { oldValue, newValue in
                newValue != nil && oldValue != newValue
            }
            .animation(reduceMotion ? nil : .snappy, value: selectedSummary?.weekStart)

            if let selectedSummary {
                WeeklySelectionCard(
                    summary: selectedSummary,
                    onClear: { selectedWeekStart = nil }
                )
                .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
            } else {
                Label("Tap or drag to explore the chart", systemImage: "hand.draw")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }

    private func pointColor(for summary: WeeklyStepSummary) -> Color {
        guard let selectedSummary else { return .accentColor }
        return summary.id == selectedSummary.id ? .accentColor : .secondary.opacity(0.45)
    }
}
