import SwiftUI
import AudioToolbox

struct CalibrationView: View {
    @ObservedObject var stepManager: StepManager
    @ObservedObject var stepTracker: StepTracker
    @Environment(\.dismiss) var dismiss

    @State private var showResult = false
    @State private var averageStepLength: Double = 0.0
    @State private var targetStepCount = 10
    @State private var calibrationStarted = false
    @State private var previousStepCount: Int = 0

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
            } else {
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
        .onChange(of: stepManager.stepCount) {
            // Compare the old value (previousStepCount) with the new value
            if calibrationStarted && stepManager.stepCount >= targetStepCount && previousStepCount < targetStepCount {
                finishCalibration()
            }
        }
    }

    private func startCalibration() {
        calibrationStarted = true
        stepTracker.reset()  // Reset stepTracker before starting calibration
        stepTracker.startTracking()
    }

    private func finishCalibration() {
        stepTracker.stopTracking()

        // Simulate average step length = total distance / step count
        // Let's assume user walks 7 meters over 10 steps
        let simulatedDistance = 7.0
        averageStepLength = simulatedDistance / Double(targetStepCount)
        stepManager.targetStepLength = Float(averageStepLength)

        // Vibrate to alert user
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        showResult = true
    }

    private func redoCalibration() {
        stepTracker.reset()  // Reset stats before retrying
        calibrationStarted = false
        showResult = false
    }
}

