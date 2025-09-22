import SwiftUI

struct GoalsSectionView: View {
    @EnvironmentObject var stepModel: StepModel
    @State private var tempGoalSteps: String = ""
    @State private var showAlert: Bool = false
    @FocusState private var isGoalFieldFocused: Bool

    var body: some View {
        Section(header: Text("Goals".localized).foregroundColor(.blue)) {
            HStack {
                Text("Daily step goal".localized)
                Spacer()
                TextField("10,000".localized, text: $tempGoalSteps)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isGoalFieldFocused)
                    .onChange(of: tempGoalSteps) { oldValue, newValue in
                        // Filter non-numeric characters while typing
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            tempGoalSteps = filtered
                        }
                    }
                    .onAppear {
                        // Initialize with current value
                        tempGoalSteps = "\(stepModel.goalSteps)"
                    }
            }
            
            Button(action: updateGoalSteps) {
                Text("Save Goal".localized)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done".localized) {
                    updateGoalSteps()
                }
            }
        }
        .alert("Invalid number".localized, isPresented: $showAlert) {
            Button("Ok".localized) {
                showAlert = false
            }
        } message: {
            Text("Please enter a valid number between 1 and 100,000.".localized)
        }
    }
    
    // MARK: - Functions
    private func updateGoalSteps() {
        // Ensure the value is a valid number
        let filtered = tempGoalSteps.filter { $0.isNumber }
        
        // If the value is empty or not a valid number, restore the previous value
        guard !filtered.isEmpty, let newGoal = Int(filtered), newGoal > 0 && newGoal <= 100000 else {
            showAlert = true
            tempGoalSteps = "\(stepModel.goalSteps)"
            isGoalFieldFocused = false
            return
        }
        
        // Update the value only if it's valid
        stepModel.goalSteps = newGoal
        tempGoalSteps = "\(newGoal)"
        isGoalFieldFocused = false
    }
}
