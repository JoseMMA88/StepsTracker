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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stepModel)
        }
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedFormat(_ args: CVarArg...) -> String {
        return String(format: self.localized, args)
    }
} 
