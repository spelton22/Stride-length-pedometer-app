import CoreMotion
import Foundation

class StepAnalyzer: ObservableObject {
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private let stepManager: StepManager
    //private let stepTracker: StepTracker
    
    
    @Published var stepLengths: [Float] = []
    @Published var lastStepLength: Float = 0.0
    @Published var average: Float = 0.0
    private var outlierCount = 0
    
    init(stepManager: StepManager) {
        self.stepManager = stepManager
    }
    
    func startAnalyzing() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.01
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let data = self.motionManager.deviceMotion else { return }
            
            let acceleration = data.userAcceleration
            let magnitude = sqrt(pow(acceleration.x, 2) +
                                 pow(acceleration.y, 2) +
                                 pow(acceleration.z, 2))
            
            let strideFactor = 0.5
            let stepLength = Float(strideFactor * magnitude)
            
            //self.stepManager.checkForStepOutliers(stepLength: stepLength)
            
            DispatchQueue.main.async {
                self.lastStepLength = stepLength
                self.addStepLength(stepLength)
            }
        }
    }
    
    func stopAnalyzing() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
    }
    
    private func addStepLength(_ length: Float) {
        stepLengths.append(length)
        if stepLengths.count % 10 == 0 {
            let avg = stepLengths.suffix(10).reduce(0, +) / 10
            average = avg
        }
    }
    
}
