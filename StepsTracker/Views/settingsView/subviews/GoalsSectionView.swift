import SwiftUI

struct GoalsSectionView: View {
    @Environment(StepModel.self) private var stepModel

    private let goalPresets = [6_000, 8_000, 10_000, 12_000]

    var body: some View {
        Section {
            Stepper(value: goalBinding, in: 1_000...100_000, step: 500) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily step goal")
                    Text(stepModel.goalSteps, format: .number)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Quick choices")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 72), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(goalPresets, id: \.self) { goal in
                        presetButton(for: goal)
                    }
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Daily goal")
        } footer: {
            Text("Your goal is saved automatically and used to calculate today’s progress.")
        }
    }

    private func presetButton(for goal: Int) -> some View {
        Button {
            Task {
                await stepModel.updateGoal(goal)
            }
        } label: {
            Text(goal, format: .number)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(goal == stepModel.goalSteps ? .accentColor : .secondary)
        .controlSize(.small)
        .accessibilityLabel("Set daily goal to \(goal.formatted()) steps")
    }

    private var goalBinding: Binding<Int> {
        Binding(
            get: { stepModel.goalSteps },
            set: { goal in
                Task {
                    await stepModel.updateGoal(goal)
                }
            }
        )
    }
}
