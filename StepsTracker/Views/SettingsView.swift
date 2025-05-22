import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var goalSteps: String = ""
    @State private var tempGoalSteps: String = ""
    @FocusState private var isGoalFieldFocused: Bool
    
    private func updateGoalSteps() {
        // Asegurarse de que el valor sea un número válido
        let filtered = tempGoalSteps.filter { $0.isNumber }
        
        // Si el valor está vacío o no es un número válido, restaurar el valor anterior
        guard !filtered.isEmpty, let newGoal = Int(filtered), newGoal > 0 else {
            tempGoalSteps = "\(stepModel.goalSteps)"
            isGoalFieldFocused = false
            return
        }
        
        // Actualizar el valor solo si es válido
        stepModel.goalSteps = newGoal
        tempGoalSteps = "\(newGoal)"
        isGoalFieldFocused = false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Vista de fondo que captura los toques
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isGoalFieldFocused = false
                    }
                
                VStack {
                    Form {
                        Section(header: Text("Goals").foregroundColor(.blue)) {
                            HStack {
                                Text("Daily step goal")
                                Spacer()
                                TextField("10,000", text: $tempGoalSteps)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .focused($isGoalFieldFocused)
                                    .onChange(of: tempGoalSteps) { oldValue, newValue in
                                        // Filtrar caracteres no numéricos mientras se escribe
                                        let filtered = newValue.filter { $0.isNumber }
                                        if filtered != newValue {
                                            tempGoalSteps = filtered
                                        }
                                    }
                                    .onAppear {
                                        // Inicializar con el valor actual
                                        tempGoalSteps = "\(stepModel.goalSteps)"
                                    }
                            }
                            
                            Button(action: updateGoalSteps) {
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
        }
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    updateGoalSteps()
                }
            }
        }
    }
} 