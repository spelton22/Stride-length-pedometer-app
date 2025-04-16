import SwiftUI
import AudioToolbox
import CoreMotion

struct CalibrationView: View {
    @ObservedObject var stepManager: StepManager
    @ObservedObject var stepTracker: StepTracker
    @Environment(\.dismiss) var dismiss

    @State private var showResult = false
    @State private var averageStepLength: Double = 0.0
    @State private var targetStepCount = 10
    @State private var calibrationStarted = false
    @State private var previousStepCount: Int = 0

    private let pedometer = CMPedometer()
    @State private var distanceWalked: Double = 0.0

    var body: some View {
        VStack(spacing: 30) {
            Text("Step Calibration")
                .font(.largeTitle)
                .bold()
            

            if showResult {
                Text("Calibration Complete!")
                    .font(.title2)

                Text("Target Step Length: \(String(format: "%.2f", averageStepLength)) meters")
                    .font(.title3)
                    .padding()

                HStack {
                    Button("Redo") {
                        redoCalibration()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)

                    Button("OK") {
                        dismiss() // Go back to home
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            else {
                Text("Please walk \(targetStepCount) steps.")
                    .font(.title3)

                Text("Steps Taken: \(stepTracker.stepCount)")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                Button("Start Calibration") {
                    startCalibration()
                }
                .disabled(calibrationStarted)
                .padding()
                .frame(maxWidth: .infinity)
                .background(calibrationStarted ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
        .onChange(of: stepTracker.stepCount) {
            let newStepCount = stepTracker.stepCount
            // Check if the step count has reached the target and update `showResult`
            if calibrationStarted && newStepCount >= targetStepCount && previousStepCount < targetStepCount {
                finishCalibration()  // This will trigger the state change
            }

            previousStepCount = newStepCount
        }
    }

    private func startCalibration() {
        calibrationStarted = true
        stepTracker.reset()  // Reset stepTracker before starting calibration
        stepTracker.startTracking()

        // Start tracking distance using the CMPedometer
        pedometer.startUpdates(from: Date()) { data, error in
            guard let data = data, error == nil else { return }
            distanceWalked = data.distance?.doubleValue ?? 0.0
        }
    }

    private func finishCalibration() {
        // Stop both step tracking and distance tracking
        showResult = true
        stepTracker.stopTracking()
        pedometer.stopUpdates()

        // Calculate average step length using the actual distance walked
        if stepTracker.stepCount > 0 {
            averageStepLength = distanceWalked / Double(stepTracker.stepCount)
        }

        // Update the step manager with the calculated step length
        stepManager.targetStepLength = Float(averageStepLength)
        stepTracker.targetStepLength = Float(averageStepLength)

        // Vibrate to alert user
        //AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        stepManager.triggerWarning()

        //showResult = true
    }

    private func redoCalibration() {
        stepTracker.reset()  // Reset stats before retrying
        calibrationStarted = false
        showResult = false
        distanceWalked = 0.0
    }
}

