import SwiftUI

/// Kept as a focused, reusable value label for future compact dashboard layouts.
struct StepCounterView: View {
    let steps: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(steps, format: .number)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 180)
            Text("steps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(progress, format: .percent.precision(.fractionLength(0)))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steps")
        .accessibilityValue("\(steps.formatted()) steps, \(Int((progress * 100).rounded())) percent")
    }
}
