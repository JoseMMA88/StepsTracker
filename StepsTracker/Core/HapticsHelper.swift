//
//  HapticsHelper.swift
//  StepsTracker
//
//  Created by Jose Manuel Malagón Alba on 22/9/25.
//


import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct HapticsHelper {
    func success() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #elseif os(watchOS)
        // On watchOS you could use:
        // WKInterfaceDevice.current().play(.success)
        // Leaving as no-op to keep this helper dependency-free here.
        #else
        // No-op for other platforms
        #endif
    }
}