//
//  StepCounterView.swift
//  StepsTracker
//
//  Created by Jose Manuel Malagón Alba on 22/9/25.
//


import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct StepCounterView: View {
    let todayStepsText: String
    let percentageText: String
    let reachedGoal: Bool

    var body: some View {
        VStack(spacing: 10) {
            Text(todayStepsText)
                .font(.system(size: 70, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: reachedGoal ? .green.opacity(0.5) : .blue.opacity(0.5), radius: 10, x: 0, y: 0)

            Text("STEPS".localized)
                .font(.headline)
                .foregroundColor(.gray)

            Text(percentageText)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray.opacity(0.5))
        }
    }
}
