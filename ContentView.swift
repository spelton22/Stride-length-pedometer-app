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

    @State private var targetLengthInput = 0.0
    @State private var isTracking = false
    @State private var finalStepCount: Int = 0
    @State private var finalStepLength2: Float = 0.0
    @State private var finalStepLength: Float = 0.0
    @State private var finalWalkingSpeed: Double = 0.0
    @State private var strideLengthRaw: Double = 0.0
    @State private var strideLengthEmpirical: Double = 0.0
    
    @State private var stepoutlierCountInput: String = ""
    @State private var speedoutlierCountInput: String = ""
    @State private var strideDeviationInput: String = ""
    @State private var speedDeviationInput: String = ""

    var body: some View {
        NavigationStack {
            Text("Stride Length Tracking")
                .font(.title)
                .foregroundColor(.white)
                .padding(.bottom)
            //Divider()
            //Text("Outlier Configuration")
                .font(.title2)
                .padding(.top)
            //Text("Outlier Steps Number")
            if finalStepCount == 0 {
                TextField("Allowed number of outlier steps", text: $stepoutlierCountInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.numberPad)
                    .onSubmit {
                        if let count = Int(stepoutlierCountInput) {
                            //stepManager.stepOutlierThreshold = count
                            stepTracker.stepOutlierThreshold = count
                        }
                    }
                //Text("Outlier Speed Number")
                TextField("Allowed number of outlier speeds", text: $speedoutlierCountInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.numberPad)
                    .onSubmit {
                        if let count = Int(speedoutlierCountInput) {
                            //stepManager.stepOutlierThreshold = count
                            stepTracker.stepOutlierThreshold = count
                        }
                    }
                //Text("Stride deviation tolerance")
                TextField("Stride deviation tolerance (m)", text: $strideDeviationInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.decimalPad)
                    .onSubmit {
                        if let tolerance = Float(strideDeviationInput) {
                            stepManager.strideLengthTolerance = tolerance
                            //stepTracker.strideLengthTolerance = tolerance
                        }
                    }
                //Text("Speed deviation tolerance")
                TextField("Speed deviation tolerance (m/s)", text: $speedDeviationInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.decimalPad)
                    .onSubmit {
                        if let tolerance = Float(speedDeviationInput) {
                            stepManager.speedTolerance = tolerance
                            //stepTracker.speedLengthTolerance = tolerance
                        }
                    }
            }
            VStack {
                NavigationLink("Calibrate Step Length") {
                    CalibrationView(stepManager: stepManager, stepTracker: stepTracker)
                }
                .padding()
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
                    
                    Text("Final raw stride: \(String(format: "%.2f m", strideLengthRaw))")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                    
                    Text("Final empirical stride: \(String(format: "%.2f m", strideLengthEmpirical))")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                }

                Text("Target Step Length (m): \(String(format: "%.4f m", stepManager.targetStepLength))")
                    .font(.headline)
                
                Text("Target Step Speed (m): \(String(format: "%.4f m", stepManager.speedThreshold))")
                    .font(.headline)
//                TextField("Enter step length", text: $targetLengthInput)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
//                    .keyboardType(.decimalPad)
//                    .onSubmit {
//                        if let target = Float(targetLengthInput) {
//                            stepManager.targetStepLength = target
//                            stepTracker.targetStepLength = target
//                        }
//                    }

                Button("Start") {
//                    if let target = Float(targetLengthInput) {
//                        stepManager.targetStepLength = target
//                        stepTracker.targetStepLength = target
//                    }
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
                            self.finalStepLength2 = stepTracker.averageStepLength2
                            self.strideLengthRaw = stepTracker.averageStrideLengthRaw
                            self.strideLengthEmpirical = stepTracker.averageStrideLengthEmpirical
                        }
                    )
                }
            }
            .padding()
        }
    }
}

