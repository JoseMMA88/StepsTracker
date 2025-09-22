//
//  DailyGoalView.swift
//  StepsTracker
//
//  Created by Jose Manuel Malagón Alba on 22/9/25.
//


import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct DailyGoalView: View {
    let goalStepsText: String
    let reachedGoal: Bool

    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.1))
            .shadow(color: reachedGoal ? .green.opacity(0.2) : .blue.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    var body: some View {
        HStack {
            Text("Daily goal:".localized)
                .font(.headline)
                .foregroundColor(.gray)

            Text("%@ steps".localizedFormat(goalStepsText))
                .font(.headline)
                .foregroundColor(reachedGoal ? .green : .blue)
        }
        .padding()
        .background(backgroundShape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily goal".localized)
        .accessibilityValue("%@ steps".localizedFormat(goalStepsText))
    }
}
