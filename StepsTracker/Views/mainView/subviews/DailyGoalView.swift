import SwiftUI

struct DailyGoalView: View {
    let steps: Int
    let goal: Int

    private var remainingSteps: Int {
        max(goal - steps, 0)
    }

    private var hasReachedGoal: Bool {
        remainingSteps == 0
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: hasReachedGoal ? "flag.checkered" : "flag.fill")
                .font(.title2)
                .foregroundStyle(hasReachedGoal ? Color.green : .accentColor)
                .frame(width: 36, height: 36)
                .background((hasReachedGoal ? Color.green : .accentColor).opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Daily goal")
                    .font(.headline)
                Text(goal, format: .number)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(hasReachedGoal ? "Complete" : "\(remainingSteps.formatted()) left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(hasReachedGoal ? .green : .secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(20)
        .background(.background, in: .rect(cornerRadius: 20))
        .shadow(color: .primary.opacity(0.06), radius: 8, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily goal")
        .accessibilityValue(
            hasReachedGoal
                ? "Goal complete. \(goal.formatted()) steps."
                : "\(remainingSteps.formatted()) steps remaining out of \(goal.formatted())."
        )
    }
}
