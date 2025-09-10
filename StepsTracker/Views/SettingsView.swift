import SwiftUI

struct SettingsView: View {
    // MARK: - Properties
    @EnvironmentObject var stepModel: StepModel
    @State private var goalSteps: String = ""
    @State private var tempGoalSteps: String = ""
    @State private var showAlert: Bool = false
    @FocusState private var isGoalFieldFocused: Bool
    
    // MARK: - Views
    var body: some View {
        NavigationView {
            ZStack {
                // Background view that captures touches
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isGoalFieldFocused = false
                    }
                
                VStack {
                    Form {
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
                        
                        Section(header: Text("Information".localized).foregroundColor(.blue)) {
                            HStack {
                                Text("Version".localized)
                                Spacer()
                                Text("1.0.0".localized)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Text("Device".localized)
                                Spacer()
                                Text(UIDevice.current.model)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Section(header: Text("Privacy".localized).foregroundColor(.blue)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Data Privacy".localized)
                                    .font(.headline)
                                
                                Text("Your step data is stored locally on your device and is never shared with third parties. We only use this data to provide you with accurate step tracking and statistics.".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                            
                            Button(action: {
                                if let url = URL(string: "https://josemalagon.github.io/stepstracker-privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Text("Privacy Policy".localized)
                                        .foregroundColor(.blue)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        Section(header: Text("About".localized).foregroundColor(.blue)) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("StepTracker".localized)
                                    .font(.headline)
                                
                                Text("This application uses device sensors to accurately track your steps and help you achieve your daily physical activity goals.".localized)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .navigationTitle("Settings".localized)
                .background(Color(hex: "101010"))
            }
        }
        .preferredColorScheme(.dark)
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
