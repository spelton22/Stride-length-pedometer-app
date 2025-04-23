import SwiftUI

struct TrackingView: View {
    @ObservedObject var stepTracker: StepTracker
    @ObservedObject var stepAnalyzer: StepAnalyzer
    //@StateObject var stepTracker = StepTracker(stepManager: StepManager())
    //@StateObject private var motion = StepTracker
    @State private var isWalking = false

    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(isWalking ? "Walking..." : "Not Walking")
                .font(.largeTitle)
                .padding()
            
            if stepTracker.stepOutlierCount > 3 {
                Text("⚠️ Warning: Too many inconsistent steps or speed variations!")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Text("Target Step Length (m): \(String(format: "%.4f m", stepTracker.targetStepLength))")
                .font(.headline)

            Text("Total Steps: \(stepTracker.stepCount)")
            Text("New Total Steps: \(stepTracker.totalSteps)")
            //Text("Last Stride Length: \(String(format: "%.2f", stepTracker.lastStepLength)) m")
            Text("10-Step Avg Stride Length: \(String(format: "%.2f", stepTracker.averageStrideLength)) m")
            //Text("Last Walking Speed: \(String(format: "%.2f", stepTracker.lastWalkingSpeed)) m/s")
            Text("10-Step Avg Walking Speed: \(String(format: "%.2f", stepTracker.averageWalkingSpeed)) m/s")
            Text("Step Outlier Count: \(stepTracker.stepOutlierCount)")
            Text("Speed Outlier Count: \(stepTracker.speedOutlierCount)")
            
//            Text("accelerometer x: \(String(format: "%.2f",stepTracker.accel_x))")
//            Text("accelerometer y: \(String(format: "%.2f",stepTracker.accel_y))")
//            Text("accelerometer z: \(String(format: "%.2f",stepTracker.accel_z))")
            
            
            Text("NEW CALCULATION")
            Text("ACCEL Steps: \(stepTracker.stepCount2)")
            Text(String(format: "Last Stride: %.2f m", stepTracker.lastStepLength2))
            Text(String(format: "Average Stride: %.2f m", stepTracker.averageStepLength2))
            
            Text("strideLengthRaw: \(String(format: "%.2f",stepTracker.averageStrideLengthRaw))")
            Text("strideLengthEmpirical: \(String(format: "%.2f",stepTracker.averageStrideLengthEmpirical))")

            if !isWalking {
                Button("Start Walk") {
                    startWalk()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Stop Walk") {
                    stopWalk()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Spacer()
        }
        .onAppear {
            // Reset all stats before starting the walk
            stepTracker.reset()
        }
    }

    private func startWalk() {
        isWalking = true
        stepTracker.startTracking() // Begin tracking steps
    }

    private func stopWalk() {
        isWalking = false
        stepTracker.stopTracking() // Stop tracking steps
        onStop() // Call the onStop closure to notify the parent view
    }
}

