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
    @Published var accel_x: Double = 0.0
    @Published var accel_y: Double = 0.0
    @Published var accel_z: Double = 0.0
    
    var targetStepLength: Float = 0.7
    
    //new calculation
    private var motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var stepCount2: Int = 0
    @Published var lastStepLength2: Float = 0.0
    @Published var averageStepLength2: Float = 0.0
    
    private var accelerationHistory: [Float] = []
    private var lastStepTime: TimeInterval = 0
    private var strideLengths2: [Float] = []

    init(stepManager: StepManager) {
        self.stepManager = stepManager
        startUpdates()
    }
    
    //new func
    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50 Hz
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let data = data else { return }

            // Using Z-axis (vertical acceleration)
            let z = data.acceleration.z
            DispatchQueue.main.async {
                self.processAcceleration(Float(z), timestamp: data.timestamp)
                self.accel_x = data.acceleration.x
                self.accel_y = data.acceleration.y
                self.accel_z = data.acceleration.z
            }
        }
    }
    
    private func processAcceleration(_ z: Float, timestamp: TimeInterval) {
        accelerationHistory.append(z)
        if accelerationHistory.count > 25 {
            accelerationHistory.removeFirst()
        }
        
        // Simple peak detection
        if accelerationHistory.count >= 3 {
            let a = accelerationHistory[accelerationHistory.count - 3]
            let b = accelerationHistory[accelerationHistory.count - 2]
            let c = accelerationHistory[accelerationHistory.count - 1]
            
            if b > a && b > c && b > 0.9 { // Peak threshold
                let timeSinceLastStep = timestamp - lastStepTime
                if timeSinceLastStep > 0.3 { // Debounce: ~max 3 steps/sec
                    stepCount2 += 1
                    lastStepTime = timestamp
                    
                    // Estimate step length (very rough!)
                    let stride = 0.5 + (timeSinceLastStep * 1.2) // Tune this!
                    lastStepLength2 = Float(stride)
                    strideLengths2.append(Float(stride))
                    averageStepLength2 = Float(strideLengths2.reduce(0, +) / Float(strideLengths2.count))
                }
            }
        }
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
        
        //new
        stepCount2 = 0
        lastStepLength2 = 0
        averageStepLength2 = 0
        accelerationHistory.removeAll()
        strideLengths2.removeAll()
        lastStepTime = 0
        
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

        if last10StepOutliers >= 3 || last10SpeedOutliers >= 5 {
            print("⚠️ Warning: Too many inconsistent steps or speed variations!")
            stepManager.triggerWarning()
            stepOutlierCount = 0  // Reset counter after buzzing
            speedOutlierCount = 0
        }
        
        let difference = abs(targetStepLength - averageStrideLength)
        if difference > 0.15 {
            stepManager.triggerWarning()
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

