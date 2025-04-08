import SwiftUI

struct ContentView: View {
    @StateObject private var stepManager = StepManager()
    @StateObject private var stepAnalyzer: StepAnalyzer
    @StateObject private var stepTracker: StepTracker
    
    init() {
        let manager = StepManager()
        _stepManager = StateObject(wrappedValue: manager)
        _stepAnalyzer = StateObject(wrappedValue: StepAnalyzer(stepManager: manager))
        _stepTracker = StateObject(wrappedValue: StepTracker(stepManager: manager))
    }

    @State private var targetLengthInput = "0.7"
    @State private var isTracking = false
    @State private var finalStepCount: Int = 0
    @State private var finalStepLength: Float = 0.0
    @State private var finalWalkingSpeed: Double = 0.0

    var body: some View {
        NavigationStack {
            Text("Stride Length Pedometer")
                .font(.title)
                .foregroundColor(.white)
                //.padding(.bottom)
            VStack {
                NavigationLink("Calibrate Step Length") {
                    CalibrationView(stepManager: stepManager, stepTracker: stepTracker)
                }
                .padding()
                //.font(.title)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)

                if finalStepCount > 0 {
                    Text("Final Step Count: \(finalStepCount)")
                        .font(.title2)
                        .foregroundColor(.red)
                        .padding(.bottom)

                    Text("Final Average Stride Length: \(String(format: "%.4f m", finalStepLength))")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .padding(.bottom)

                    Text("Final Average Speed: \(String(format: "%.2f m/s", finalWalkingSpeed))")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                }

                Text("Target Step Length (m)")
                    .font(.headline)
                TextField("Enter step length", text: $targetLengthInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .keyboardType(.decimalPad)
                    .onSubmit {
                        if let target = Float(targetLengthInput) {
                            stepManager.targetStepLength = target
                            stepTracker.targetStepLength = target
                        }
                    }

                Button("Start") {
                    if let target = Float(targetLengthInput) {
                        stepManager.targetStepLength = target
                        stepTracker.targetStepLength = target
                    }
                    isTracking = true
                }
                .font(.largeTitle)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
                .padding()

                .navigationDestination(isPresented: $isTracking) {
                    TrackingView(
                        stepTracker: stepTracker,
                        stepAnalyzer: stepAnalyzer,
                        onStop: {
                            self.finalStepCount = stepTracker.stepCount
                            self.finalStepLength = stepTracker.averageStrideLength
                            self.finalWalkingSpeed = Double(stepTracker.averageWalkingSpeed)
                            self.isTracking = false
                        }
                    )
                }
            }
            .padding()
        }
    }
}

