import CoreMotion
import Foundation

class StepTracker: ObservableObject {
    private let pedometer = CMPedometer()
    private let stepManager: StepManager
    private var timer: Timer?

    @Published var stepLengths: [Float] = []
    @Published var walkingSpeeds: [Float] = []  // NEW: Stores last 10 walking speeds
    @Published var lastStepLength: Float = 0.0
    @Published var stepCount: Int = 0
    @Published var averageStrideLength: Float = 0.0
    @Published var lastWalkingSpeed: Float = 0.0
    @Published var averageWalkingSpeed: Float = 0.0
    @Published var stepOutlierCount: Int = 0
    @Published var speedOutlierCount: Int = 0
    @Published var showOutlierWarning = false

    var targetStepLength: Float = 0.7

    init(stepManager: StepManager) {
        self.stepManager = stepManager
    }
    
    func reset() {
        stepCount = 0
        averageStrideLength = 0.0
        lastWalkingSpeed = 0.0
        lastStepLength = 0.0
        averageWalkingSpeed = 0.0
        
        stepLengths.removeAll()
        walkingSpeeds.removeAll()
        
        stepOutlierCount = 0
        speedOutlierCount = 0
        
    }

    func startTracking() {
        guard CMPedometer.isPedometerEventTrackingAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let self = self, error == nil, let data = data else { return }
            
            let stepLength = self.calculateStepLength(from: data)
            let speed = Float(data.currentPace?.doubleValue ?? 0)

            DispatchQueue.main.async {
                self.lastStepLength = stepLength
                self.lastWalkingSpeed = speed
                self.addStepData(stepLength: stepLength, speed: speed)
                self.stepCount = data.numberOfSteps.intValue
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
        timer?.invalidate()
    }

    private func addStepData(stepLength: Float, speed: Float) {
        stepLengths.append(stepLength)
        walkingSpeeds.append(speed)

        // Track step length outliers
        if stepManager.checkForStepOutliers(stepLength: stepLength) {
            stepOutlierCount += 1
        }

        // Track walking speed outliers
        if stepManager.checkForSpeedOutliers(speed: speed) {
            speedOutlierCount += 1
        }

        // Keep only the last 10 steps/speeds for detection
        if stepLengths.count > 10 {
            stepLengths.removeFirst()
        }
        if walkingSpeeds.count > 10 {
            walkingSpeeds.removeFirst()
        }

        // Check for outliers in last 10 steps
        let last10StepOutliers = stepLengths.filter { stepManager.checkForStepOutliers(stepLength: $0) }.count
        let last10SpeedOutliers = walkingSpeeds.filter { stepManager.checkForSpeedOutliers(speed: $0) }.count

        if last10StepOutliers >= 5 || last10SpeedOutliers >= 5 {
            print("⚠️ Warning: Too many inconsistent steps or speed variations!")
            stepManager.triggerWarning()
            stepOutlierCount = 0  // Reset counter after buzzing
            speedOutlierCount = 0
        }

        // Update averages
        if stepLengths.count > 0 {
            averageStrideLength = stepLengths.reduce(0, +) / Float(stepLengths.count)
        }
        if walkingSpeeds.count > 0 {
            averageWalkingSpeed = walkingSpeeds.reduce(0, +) / Float(walkingSpeeds.count)
        }
    }

    private func calculateStepLength(from data: CMPedometerData) -> Float {
        return Float(data.distance?.doubleValue ?? 0) / Float(data.numberOfSteps.intValue)
    }
}

