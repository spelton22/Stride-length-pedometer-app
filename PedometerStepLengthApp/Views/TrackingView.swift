import SwiftUI

struct TrackingView: View {
    @ObservedObject var stepTracker: StepTracker
    @ObservedObject var stepManager: StepManager
    @ObservedObject var stepAnalyzer: StepAnalyzer
    @StateObject var locationManager = LocationManager()
    @State private var isWalking = false
    @State private var isPaused = false

    var onStop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(isWalking ? (isPaused ? "Paused" : "Walking...") : "Not Walking")
                .font(.largeTitle)
                .padding()
            
            if stepTracker.stepOutlierCount > stepTracker.stepOutlierThreshold {
                Text("⚠️ Warning: Too many inconsistent steps or speed variations!")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Text("Target Step Length: \(String(format: "%.4f inches", stepTracker.targetStepLength * 39.3700787402))")
                .font(.headline)
            Text("Target Walking Speed: \(String(format: "%.4f inches/s", stepManager.speedThreshold * 39.3700787402))")
                .font(.headline)

            Text("Total Steps: \(stepTracker.stepCount)")
            Text("Walk Distance: \((locationManager.totalDistance * 39.3700787402) / 12, specifier: "%.2f") feet")
            Text("Walk Duration: \(String(format: "%.2f seconds", stepTracker.walkDuration))")
            
            Text("Avg Stride Length: \(String(format: "%.2f", stepTracker.averageStrideLength * 39.3700787402)) inches")
//            Text("Avg Walking Speed (inches/s): \(String(format: "%.2f", stepTracker.averageWalkingSpeed * 39.3700787402)) m/s")
//            Text("Step Outlier Count: \(stepTracker.stepOutlierCount)")
//            Text("Speed Outlier Count: \(stepTracker.speedOutlierCount)")
        
            if !isWalking {
                Button("Start Walk") {
                    startWalk()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                if isPaused {
                    Button("Resume Walk") {
                        resumeWalk()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    Button("Pause Walk") {
                        pauseWalk()
                    }
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }

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
        stepTracker.step_tracker_total_distance = 0
        isWalking = true
        stepTracker.startTracking() // Begin tracking steps
        locationManager.totalDistance = 0
        stepTracker.walkDuration = 0
        locationManager.start()
    }

    private func stopWalk() {
        stepTracker.step_tracker_total_distance = (locationManager.totalDistance * 39.3700787402) / 12
        isWalking = false
        stepTracker.stopTracking() // Stop tracking steps
        onStop() // Call the onStop closure to notify the parent view
        locationManager.stop()
    }
    
    private func pauseWalk() {
        stepTracker.step_tracker_total_distance = (locationManager.totalDistance * 39.3700787402) / 12
        isPaused = true
        stepTracker.stopTracking()
        locationManager.pause()
    }

    private func resumeWalk() {
        stepTracker.step_tracker_total_distance = (locationManager.totalDistance * 39.3700787402) / 12
        isPaused = false
        stepTracker.startTracking()
        locationManager.resume()
    }
    
}

