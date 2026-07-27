import SwiftUI

struct SelectionCard: View {
    let entry: DailyStep
    let goal: Int
    let onClear: () -> Void

    private var difference: Int {
        entry.steps - goal
    }

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: entry.steps >= goal ? "checkmark.circle.fill" : "figure.walk")
                    .font(.title2)
                    .foregroundStyle(entry.steps >= goal ? Color.green : .accentColor)
                    .frame(width: 44, height: 44)
                    .background((entry.steps >= goal ? Color.green : .accentColor).opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.headline)
                    Text(entry.steps, format: .number)
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Text(differenceText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
            .accessibilityValue("\(String(localized: "\(entry.steps) steps")). \(differenceText)")

            Spacer(minLength: 0)

            Button(action: onClear) {
                Label("Clear selection", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear selection")
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 16))
        .shadow(color: .primary.opacity(0.06), radius: 8, y: 4)
    }

    private var differenceText: String {
        difference >= 0
            ? String(localized: "\(difference) above your goal")
            : String(localized: "\(-difference) below your goal")
    }
}

struct WeeklySelectionCard: View {
    let summary: WeeklyStepSummary
    let onClear: () -> Void

    private var weekEnd: Date {
        Calendar.autoupdatingCurrent.date(byAdding: .day, value: 6, to: summary.weekStart) ?? summary.weekStart
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 0) {
                    Text(summary.weekStart, format: .dateTime.month(.abbreviated).day())
                    Text(" – ")
                    Text(weekEnd, format: .dateTime.month(.abbreviated).day())
                }
                .font(.headline)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 18) {
                        metrics
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        metrics
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Selected week")

            Spacer(minLength: 0)

            Button(action: onClear) {
                Label("Clear selection", systemImage: "xmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Clear selection")
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.08), in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var metrics: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text("Daily average")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary.averageDailySteps, format: .number)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: "chart.line.uptrend.xyaxis")
        }

        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text("Weekly total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(summary.totalSteps, format: .number)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: "sum")
        }
    }
}
