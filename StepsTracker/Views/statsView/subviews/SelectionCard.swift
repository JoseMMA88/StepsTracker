import SwiftUI

struct SelectionCard: View {
    let entry: DailyStep
    let goal: Int

    private var difference: Int {
        entry.steps - goal
    }

    var body: some View {
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
                Text(differenceText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.background, in: .rect(cornerRadius: 16))
        .shadow(color: .primary.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
        .accessibilityValue("\(entry.steps.formatted()) steps. \(differenceText)")
    }

    private var differenceText: String {
        difference >= 0
            ? "\(difference.formatted()) above your goal"
            : "\((-difference).formatted()) below your goal"
    }
}
