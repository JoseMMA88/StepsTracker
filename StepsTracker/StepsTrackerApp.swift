//
//  StepsTrackerApp.swift
//  StepsTracker
//
//  Created by Jose Manuel Malagón Alba on 15/5/25.
//

import SwiftUI

@main
struct StepTrackerApp: App {
    @StateObject private var stepModel = StepModel()
    
    init() {
        // Inicializar el NotificationManager
        _ = NotificationManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stepModel)
        }
    }
}
