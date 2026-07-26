//
//  StepsTrackerApp.swift
//  StepsTracker
//
//  Created by Jose Manuel Malagón Alba on 15/5/25.
//

import SwiftUI

@main
struct StepTrackerApp: App {
    @State private var stepModel: StepModel

    init() {
        #if DEBUG && targetEnvironment(simulator)
        _stepModel = State(initialValue: StepModel(stepDataProvider: DemoStepDataProvider()))
        #else
        _stepModel = State(initialValue: StepModel())
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(stepModel)
        }
    }
}
