import SwiftUI

struct ContentView: View {
    @StateObject private var stepManager = StepManager()
    @StateObject private var stepAnalyzer: StepAnalyzer
    @StateObject private var stepTracker: StepTracker
    @StateObject var locationManager = LocationManager()

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
    @State private var averageInput: String = ""
    @State private var strideLengthInput: String = ""
    @State private var speedoutlierCountInput: String = ""
    @State private var strideDeviationInput: String = ""
    @State private var speedDeviationInput: String = ""

    @FocusState private var isFocused: Bool
    @FocusState private var isFocused1: Bool
    @FocusState private var isFocused2: Bool
    @FocusState private var isFocused3: Bool
    @FocusState private var isFocused4: Bool
    @FocusState private var isFocused5: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Stride Length Tracking")
                        .font(.title)
                        .foregroundColor(.blue)
                        .padding(.bottom)
                        .font(.title2)
                        .padding(.top)

                    Text("Target Step Length (inches): \(String(format: "%.4f m", stepManager.targetStepLength * 39.3700787402))")
                        .font(.headline)

                    Text("Target Walking Speed (inches/s): \(String(format: "%.4f m", stepManager.speedThreshold * 39.3700787402))")
                        .font(.headline)

                    TextField("Target Stride length (inches)", text: $strideLengthInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onSubmit {
                            if let stride = Float(strideLengthInput) {
                                stepManager.targetStepLength = stride
                            }
                        }

                    TextField("Number of Steps for Average", text: $averageInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused1)
                        .onSubmit {
                            if let avg = Int(averageInput) {
                                stepTracker.averageNumber = avg
                            }
                        }

                    TextField("Allowed number of outlier steps", text: $stepoutlierCountInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused2)
                        .onSubmit {
                            if let count = Int(stepoutlierCountInput) {
                                stepTracker.stepOutlierThreshold = count
                            }
                        }

                    TextField("Allowed number of outlier speeds", text: $speedoutlierCountInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused3)
                        .onSubmit {
                            if let count = Int(speedoutlierCountInput) {
                                stepTracker.speedOutlierThreshold = count
                            }
                        }

                    TextField("Stride deviation tolerance (inches)", text: $strideDeviationInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused4)
                        .onSubmit {
                            if let tolerance = Float(strideDeviationInput) {
                                stepManager.strideLengthTolerance = tolerance / 39.3700787402
                            }
                        }

                    TextField("Speed deviation tolerance (inches/s)", text: $speedDeviationInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .keyboardType(.decimalPad)
                        .focused($isFocused5)
                        .onSubmit {
                            if let tolerance = Float(speedDeviationInput) {
                                stepManager.speedTolerance = tolerance / 39.3700787402
                            }
                        }

                    if finalStepCount > 0 {
                        Group {
                            Text("Final Step Count: \(finalStepCount)")
                            Text("Percentage of Good Steps: \(String(format: "%.2f", (Double(finalStepCount - stepTracker.totalOutlierSteps) / Double(finalStepCount)) * 100))%")
                            Text("Walk Duration: \(String(format: "%.2f seconds", stepTracker.walkDuration))")
                            Text("Walk Distance: \(stepTracker.step_tracker_total_distance, specifier: "%.2f") feet")
                            //Text("Walk Distance: \((locationManager.totalDistance * 39.3700787402) / 12, specifier: "%.2f") feet")
                            Text("Final Average Stride Length: \(String(format: "%.4f", finalStepLength * 39.3700787402)) inches")
                            Text("Final Average Speed: \(String(format: "%.2f", finalWalkingSpeed * 39.3700787402)) inches/s")
                        }
                        .font(.title2)
                        .foregroundColor(.blue)
                    }

                    Button("Start") {
                        isTracking = true
                    }
                    .font(.largeTitle)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)

                    NavigationLink("Calibrate Step Length") {
                        CalibrationView(stepManager: stepManager, stepTracker: stepTracker)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Done") {
                        isFocused = false
                        isFocused1 = false
                        isFocused2 = false
                        isFocused3 = false
                        isFocused4 = false
                        isFocused5 = false
                    }
                }
            }
            .navigationDestination(isPresented: $isTracking) {
                TrackingView(
                    stepTracker: stepTracker,
                    stepManager: stepManager,
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
    }
}
