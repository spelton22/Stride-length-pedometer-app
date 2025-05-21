

import CoreMotion
import Foundation

class StepTracker: ObservableObject {
    private let pedometer = CMPedometer()
    private let stepManager: StepManager
    private var timer: Timer?
    
    @Published var totalSteps: Int = 0
    
    @Published var step_tracker_total_distance: Double = 0.0
    
    @Published var averageNumber: Int = 10
    @Published var totalOutlierSteps: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var strideLengths: [Double] = []
    private var previousAcceleration: CMAcceleration?
    private var previousRotation: CMRotationRate?
    private var previousUpdateTime: Date?
    @Published var stepOutlierThreshold: Int = 5
    @Published var speedOutlierThreshold: Int = 5
    
    @Published var strideLengthRawValues: [Double] = []
    @Published var strideLengthEmpiricalValues: [Double] = []
    @Published var averageStrideLengthRaw: Double = 0.0
    @Published var averageStrideLengthEmpirical: Double = 0.0

    private var peakAcceleration: Double = 0.0
    private var lastStepTime2: Date?
    private var stepFrequencies: [Double] = []
    
    //variable for duration of walk
    @Published private var walkStartTime: Date?
    @Published var walkDuration: TimeInterval = 0

    var empiricalK: Double = 0.37 // Tunable constant for empirical model -- calibrated in calibration step

    @Published var stepLengths: [Float] = []
    @Published var walkingSpeeds: [Float] = []  // Stores walking speeds
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
    
    // New calculation
    private var motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private let queue2 = OperationQueue()
    
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
    
    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 50.0 // 50 Hz
        
        guard motionManager.isGyroAvailable else { return }
        motionManager.startGyroUpdates()
        motionManager.gyroUpdateInterval = 1.0 / 50.0
        
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let data = data else { return }

            // Using Z-axis (vertical acceleration)
            let z = data.acceleration.z
            DispatchQueue.main.async {
                self.processAcceleration(Float(z), timestamp: data.timestamp)
//                self.accel_x = data.acceleration.x
//                self.accel_y = data.acceleration.y
//                self.accel_z = data.acceleration.z
            }
        
        }
    }
    
    private func processAcceleration(_ z: Float, timestamp: TimeInterval) {
        accelerationHistory.append(z)
        if accelerationHistory.count > 25 {
            accelerationHistory.removeFirst()
        }
        
        // accelerometer peak detection
        if accelerationHistory.count >= 3 {
            let a = accelerationHistory[accelerationHistory.count - 3]
            let b = accelerationHistory[accelerationHistory.count - 2]
            let c = accelerationHistory[accelerationHistory.count - 1]
            
            if b > a && b > c && b > 0.9 { // Peak threshold
                let currentTime = timestamp
                let timeSinceLastStep = timestamp - lastStepTime
                if timeSinceLastStep > 0.3 { // Debounce: ~max 3 steps/sec
                    stepCount2 += 1
                    lastStepTime = currentTime
                    
                    // Estimate step length (very rough!)
                    let stride = 0.5 + (timeSinceLastStep * 1.2) // Tune this!
                    lastStepLength2 = Float(stride)
                    strideLengths2.append(Float(stride))
                    averageStepLength2 = Float(strideLengths2.reduce(0, +) / Float(strideLengths2.count))
                    
                    // Update peak acceleration after detecting the step
                    self.updatePeakAcceleration(acceleration: z)
                    
                    // Call registerStep function when a step is detected
                    // Pass the current accelerometer and gyroscope data (acceleration and rotation)
                    if let currentAcceleration = motionManager.accelerometerData?.acceleration,
                       let currentRotation = motionManager.gyroData?.rotationRate {
                        print("✅ Step detected, registering stride lengths")
                        self.registerStep(acceleration: currentAcceleration, rotationRate: currentRotation)
                    }
                }
            }
        }
    }
    
    //reset function which initializes everything to 0, used when new walk is started
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
        
        // Reset step tracking variables
        stepCount2 = 0
        lastStepLength2 = 0
        averageStepLength2 = 0
        accelerationHistory.removeAll()
        strideLengths2.removeAll()
        lastStepTime = 0
        
        strideLengthRawValues.removeAll()
        strideLengthEmpiricalValues.removeAll()
        strideLengths.removeAll()
        averageStrideLengthRaw = 0.0
        averageStrideLengthEmpirical = 0.0
        totalSteps = 0
        totalDistance = 0.0
        previousAcceleration = nil
        previousRotation = nil
        previousUpdateTime = nil
        peakAcceleration = 0.0
    }

    func startTracking() {
        walkStartTime = Date()
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
        if let startTime = walkStartTime {
            walkDuration = Date().timeIntervalSince(startTime)
        }
        pedometer.stopUpdates()
        timer?.invalidate()
    }

    private func addStepData(stepLength: Float, speed: Float) {
        stepLengths.append(stepLength)
        walkingSpeeds.append(speed)

        // Track step length outliers
        if stepManager.checkForStepOutliers(stepLength: stepLength) {
            stepOutlierCount += 1
            totalOutlierSteps += 1
        }

        // Track walking speed outliers
        if stepManager.checkForSpeedOutliers(speed: speed) {
            speedOutlierCount += 1
        }

        // Keep only the last 10 steps/speeds for detection
        if stepLengths.count > averageNumber {
            stepLengths.removeFirst()
        }
        if walkingSpeeds.count > averageNumber {
            walkingSpeeds.removeFirst()
        }

        // Check for outliers in last 10 steps
//        let last10StepOutliers = stepLengths.filter { stepManager.checkForStepOutliers(stepLength: $0) }.count
//        let last10SpeedOutliers = walkingSpeeds.filter { stepManager.checkForSpeedOutliers(speed: $0) }.count

        if stepOutlierCount >= stepOutlierThreshold || speedOutlierCount >= speedOutlierThreshold {
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

    
    // MARK: - THE FUNCTIONS BELOW ARE CALCULATING THE STRIDE LENGTH WITH RAW ACCELEROMETER AND
    // GYROSCOPE DATA, THESE VALUES ARE NOT USED IN THE OUTPUT BUT OFFER ANOTHER WAY TO CALCULATE
    // THE STRIDE LENGHT IF NEEDED --> ORIGINAL USE FOR FINDING THE MOST ACCURATE STRIDE LENGTH
    // CALCULATION
    
    // NEW: Function to register step with both methods
    func registerStep(acceleration: CMAcceleration, rotationRate: CMRotationRate) {
        let strideLengthRaw = calculateStrideLengthRawSensorFusion(currentAcceleration: acceleration, currentRotation: rotationRate)
        let strideLengthEmpirical = registerStepWithPeakAcceleration()
        
        strideLengthRawValues.append(strideLengthRaw)
        strideLengthEmpiricalValues.append(strideLengthEmpirical)
        //stepCount += 1

        strideLengths.append(contentsOf: [strideLengthRaw, strideLengthEmpirical])
        totalDistance += strideLengthRaw // or use an average if you prefer
        totalSteps += 1
        
        if totalSteps % averageNumber == 0 {
            print("10 steps happened for raw and empirical!!")
            calculateAverages()
        }
        
        print("stride length raw \(String(format: "%.2f", strideLengthRaw)) meters")
        print("stride length empirical \(String(format: "%.2f", strideLengthEmpirical)) meters")
        
//        strideLengthRaw_print = Float(strideLengthRaw)
//        strideLengthEmpirical_print = Float(strideLengthEmpirical)
        
    }
    
    private func calculateAverages() {
        // Calculate the average of the last 10 stride lengths
        //let rawStrideLengthAvg = strideLengthRawValues.suffix(10).reduce(0, +) / 10.0
        let recentStrideValues = strideLengthRawValues.suffix(Int(averageNumber))
        averageStrideLengthRaw = recentStrideValues.isEmpty ? 0 : recentStrideValues.reduce(0, +) / Double(recentStrideValues.count)
        
        let empiricalStrideLengthAvg = strideLengthEmpiricalValues.suffix(Int(averageNumber))
        averageStrideLengthEmpirical = empiricalStrideLengthAvg.reduce(0, +) / Double(averageNumber)
        
        print("✅ Calculating averages")
        print("Raw avg: \(averageStrideLengthRaw), Empirical avg: \(averageStrideLengthEmpirical)")
    }

    // MARK: - Raw Sensor Fusion Stride Length
    func calculateStrideLengthRawSensorFusion(currentAcceleration: CMAcceleration, currentRotation: CMRotationRate) -> Double {
        
        guard let previousAccel = previousAcceleration,
              let previousGyro = previousRotation,
              let previousTime = previousUpdateTime else {
            previousAcceleration = currentAcceleration
            previousRotation = currentRotation
            previousUpdateTime = Date()
            return 0.0
        }

        let currentTime = Date()
        let dt = currentTime.timeIntervalSince(previousTime)

        // Integrate acceleration to velocity
        let accDiffX = currentAcceleration.x - previousAccel.x
        let accDiffY = currentAcceleration.y - previousAccel.y
        let accDiffZ = currentAcceleration.z - previousAccel.z
        let avgAcc = sqrt(accDiffX * accDiffX + accDiffY * accDiffY + accDiffZ * accDiffZ)
        let velocity = avgAcc * dt

        // Integrate gyroscope for orientation change (approximate)
        let rotMag = sqrt(pow(currentRotation.x - previousGyro.x, 2) +
                          pow(currentRotation.y - previousGyro.y, 2) +
                          pow(currentRotation.z - previousGyro.z, 2))

        // Use simple empirical fusion model
        let strideLength = (velocity + rotMag) * 2.0 // scaling factor

        // Update previous values
        previousAcceleration = currentAcceleration
        previousRotation = currentRotation
        previousUpdateTime = currentTime

        return strideLength
    }

    // MARK: - Peak Acceleration + Step Frequency Model
    func registerStepWithPeakAcceleration() -> Double {
        let stepFrequency = 0.3 // Example: calculate step frequency with time intervals between peaks
        let peakAccel = peakAcceleration
        let strideLength = empiricalK * peakAccel * stepFrequency

        return strideLength
    }

    // MARK: - New Method to Update Peak Acceleration
    func updatePeakAcceleration(acceleration: Float) {
        let newPeak = abs(acceleration)
        if Double(newPeak) > peakAcceleration {
            peakAcceleration = Double(newPeak)
        }
    }

    // MARK: - New Method to Calibrate Empirical K
    func calibrateEmpiricalK() {
        // Example: tune empiricalK based on collected data
        let averageStride = strideLengths.reduce(0, +) / Double(strideLengths.count)
        let averageAcceleration = peakAcceleration // This could be tuned further
        
//        empiricalK = averageStride / averageAcceleration
//        print("New empiricalK: \(empiricalK)")
        
        // Avoid division by zero
        if averageAcceleration != 0 {
            empiricalK = averageStride / averageAcceleration
            print("New empiricalK: \(empiricalK)")
        } else {
            print("⚠️ Warning: Peak acceleration is 0. Cannot calibrate empiricalK.")
        }

        // ✅ Reset peakAcceleration so it doesn't skew future calibrations
        peakAcceleration = 0.0
    }
}

