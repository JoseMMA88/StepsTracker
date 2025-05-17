import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var goalSteps: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Objetivos").foregroundColor(.blue)) {
                        HStack {
                            Text("Meta diaria de pasos")
                            Spacer()
                            TextField("10,000", text: $goalSteps)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onAppear {
                                    goalSteps = "\(stepModel.goalSteps)"
                                }
                        }
                        
                        Button(action: {
                            if let newGoal = Int(goalSteps), newGoal > 0 {
                                stepModel.goalSteps = newGoal
                            }
                        }) {
                            Text("Guardar Meta")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    Section(header: Text("Información").foregroundColor(.blue)) {
                        HStack {
                            Text("Versión")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Dispositivo")
                            Spacer()
                            Text(UIDevice.current.model)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text("Acerca de").foregroundColor(.blue)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("StepTracker")
                                .font(.headline)
                            
                            Text("Esta aplicación utiliza los sensores del dispositivo para hacer un seguimiento preciso de tus pasos y ayudarte a alcanzar tus objetivos diarios de actividad física.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .background(Color(hex: "101010"))
        }
        .preferredColorScheme(.dark)
    }
} 