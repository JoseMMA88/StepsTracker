import SwiftUI
import Foundation
import CoreMotion
import HealthKit

struct MainView: View {
    @EnvironmentObject var stepModel: StepModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                // Círculo principal futurista
                ZStack {
                    // Fondo circular
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 20
                        )
                    
                    // Progreso circular animado
                    Circle()
                        .trim(from: 0, to: CGFloat(stepModel.progress()))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: stepModel.progress())
                    
                    // Círculo interior con efecto de brillo
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.2), Color.black.opacity(0.05)]),
                                center: .center,
                                startRadius: 0,
                                endRadius: geometry.size.width * 0.4
                            )
                        )
                        .padding(30)
                    
                    // Contador de pasos con animación
                    VStack(spacing: 10) {
                        Text("\(stepModel.todaySteps)")
                            .font(.system(size: 70, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        Text("PASOS")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("\(Int(stepModel.progress() * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                .black
                            )
                    }
                }
                .frame(width: min(geometry.size.width * 0.85, 350))
                .padding()
                
                // Meta diaria
                HStack {
                    Text("Meta diaria:")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("\(stepModel.goalSteps) pasos")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.1))
                        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 5)
                )
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(hex: "101010")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
    }
}

// Extension para crear colores desde hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
