import Foundation
import CoreHaptics

class StepManager: ObservableObject {
    private var hapticEngine: CHHapticEngine?
    @Published var stepCount: Int = 0
    
    @Published var targetStepLength: Float = 0.0
    @Published var speedThreshold: Float = 0.0  // Walking speed threshold
    
    //@Published var stepOutlierThreshold: Int = 3
    @Published var strideLengthTolerance: Float = 0.15 // in meters
    @Published var speedTolerance: Float = 0.2 // in meters
    
    init() {
        prepareHaptics()
    }

    func checkForStepOutliers(stepLength: Float) -> Bool {
        let difference = abs(targetStepLength - stepLength)
        return difference > strideLengthTolerance
    }

    func checkForSpeedOutliers(speed: Float) -> Bool {
        let difference = abs(speedThreshold - speed)
        return difference > speedTolerance
    }

    func triggerWarning() {
        buzz()
    }

    private func prepareHaptics() {
         guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
         do {
             hapticEngine = try CHHapticEngine()
             try hapticEngine?.start()
         } catch {
             print("Haptic Engine failed to start: \(error.localizedDescription)")
         }
     }
    
    private func buzz() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)

        // Use a continuous haptic with duration
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensity, sharpness],
            relativeTime: 0,
            duration: 0.5 // Half a second buzz
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}

