import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var goalSteps: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Goals").foregroundColor(.blue)) {
                        HStack {
                            Text("Daily step goal")
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
                            Text("Save Goal")
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
                    
                    Section(header: Text("Information").foregroundColor(.blue)) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gray)
                        }
                        
                        HStack {
                            Text("Device")
                            Spacer()
                            Text(UIDevice.current.model)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Section(header: Text("About").foregroundColor(.blue)) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("StepTracker")
                                .font(.headline)
                            
                            Text("This application uses device sensors to accurately track your steps and help you achieve your daily physical activity goals.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .background(Color(hex: "101010"))
        }
        .preferredColorScheme(.dark)
    }
} 