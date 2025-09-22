import SwiftUI

// MARK: - Selection Card with Futuristic Animations
struct SelectionCard: View {
    let selectedDay: String
    let selectedSteps: Int
    @Binding var typingSteps: Int
    @Binding var glowPulse: Bool
    @Binding var scanningPosition: CGFloat
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                HStack {
                    AnimatedIcon(glowPulse: $glowPulse)
                    DayInfoSection(selectedDay: selectedDay)
                    Spacer()
                    StepsInfoSection(typingSteps: $typingSteps)
                }
                .padding()
                .background(CardBackground(glowPulse: $glowPulse, scanningPosition: $scanningPosition))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .compositingGroup()
            }
            
            InstructionText(glowPulse: $glowPulse)
        }
        .padding(.horizontal)
        .scaleEffect(glowPulse ? 1.0 : 0.95)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top))
        ))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedDay)
    }
}

// MARK: - Selection Card Components
struct AnimatedIcon: View {
    @Binding var glowPulse: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(iconGradient)
                .frame(width: 50, height: 50)
                .scaleEffect(glowPulse ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
            
            Image(systemName: "calendar.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
                .shadow(color: .cyan, radius: glowPulse ? 8 : 4)
                .rotationEffect(.degrees(glowPulse ? 5 : 0))
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
        }
    }
    
    private var iconGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
            center: .center,
            startRadius: 0,
            endRadius: 25
        )
    }
}

struct DayInfoSection: View {
    let selectedDay: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Selected Day".localized)
                .font(.caption)
                .foregroundColor(.gray)
            
            // Parse and display day and date separately for better visual hierarchy
            if selectedDay.contains(" ") {
                let components = selectedDay.components(separatedBy: " ")
                if components.count >= 2 {
                    Text(components[0]) // Day name (e.g., "Wed")
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.8), radius: 2)
                    
                    // Convert technical date format to user-friendly format
                    if let date = DateFormatter.parseFromFullFormat(selectedDay) {
                        Text(DateFormatter.displayFormat(date)) // e.g., "05 Sep, 2025"
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 1)
                    } else {
                        Text(components[1]) // Fallback to original format
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .shadow(color: .cyan.opacity(0.6), radius: 1)
                    }
                } else {
                    Text(selectedDay)
                        .font(.headline)
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.8), radius: 2)
                }
            } else {
                Text(selectedDay)
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(color: .green.opacity(0.8), radius: 2)
            }
        }
    }
}

struct StepsInfoSection: View {
    @Binding var typingSteps: Int
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Steps".localized)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("\(typingSteps)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
                .shadow(color: .cyan, radius: 4)
                .contentTransition(.numericText())
        }
    }
}

struct CardBackground: View {
    @Binding var glowPulse: Bool
    @Binding var scanningPosition: CGFloat
    
    var body: some View {
        ZStack {
            GlowBackground(glowPulse: $glowPulse)
            AnimatedBorder(glowPulse: $glowPulse)
            // Evita que la línea de escaneo toque el borde (fuente de flicker)
            ScanningLine(scanningPosition: $scanningPosition)
                .mask(
                    RoundedRectangle(cornerRadius: 15)
                        .inset(by: 3)
                )
        }
        .compositingGroup()
        .drawingGroup(opaque: false, colorMode: .linear)
    }
}

struct GlowBackground: View {
    @Binding var glowPulse: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(Color.black.opacity(0.4))
            .shadow(color: .green.opacity(glowPulse ? 0.32 : 0.22), radius: glowPulse ? 16 : 10)
            .scaleEffect(glowPulse ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
}

struct AnimatedBorder: View {
    @Binding var glowPulse: Bool
    
    private let borderWidth: CGFloat = 2
    
    var body: some View {
        // Inset leve para alinear el trazo a píxel y reducir aliasing en tamaños impares
        RoundedRectangle(cornerRadius: 15)
            .inset(by: borderWidth / 2)
            .strokeBorder(borderGradient, lineWidth: borderWidth) // ancho fijo
            .opacity(glowPulse ? 1.0 : 0.75) // anima opacidad en lugar de grosor
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .green.opacity(glowPulse ? 0.9 : 0.6), location: 0),
                .init(color: .cyan.opacity(glowPulse ? 0.7 : 0.45), location: 0.5),
                .init(color: .green.opacity(glowPulse ? 0.9 : 0.6), location: 1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct ScanningLine: View {
    @Binding var scanningPosition: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(scanLineGradient)
            .frame(width: 3) // ligeramente menor para reducir aliasing
            .offset(x: scanningPosition)
            .clipped()
            .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: scanningPosition)
    }
    
    private var scanLineGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [.clear, .cyan.opacity(0.6), .clear]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct InstructionText: View {
    @Binding var glowPulse: Bool
    
    var body: some View {
        Text("Tap the same day to deselect".localized)
            .font(.caption)
            .foregroundColor(.gray.opacity(0.7))
            .shadow(color: .green.opacity(0.3), radius: 1)
            .padding(.bottom, 5)
            .opacity(glowPulse ? 0.8 : 0.6)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPulse)
    }
}

// MARK: - Animation Manager
class AnimationManager: ObservableObject {
    /// Animates typing effect for step counting
    static func animateTypingEffect(targetSteps: Int, typingSteps: Binding<Int>) {
        typingSteps.wrappedValue = 0
        let stepIncrement = max(1, targetSteps / 30) // Animate over ~30 frames
        let duration = 0.5 // Total duration in seconds
        let frameInterval = duration / Double(max(1, targetSteps / stepIncrement))
        
        Timer.scheduledTimer(withTimeInterval: frameInterval, repeats: true) { timer in
            withAnimation(.easeOut(duration: 0.1)) {
                if typingSteps.wrappedValue < targetSteps {
                    typingSteps.wrappedValue = min(typingSteps.wrappedValue + stepIncrement, targetSteps)
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
