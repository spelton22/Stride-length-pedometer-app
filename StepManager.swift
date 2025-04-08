import Foundation
import CoreHaptics

class StepManager: ObservableObject {
    @Published var targetStepLength: Float = 0.0
    private var hapticEngine: CHHapticEngine?
    @Published var stepCount: Int = 0
    private let speedThreshold: Float = 1.3  // Walking speed threshold

    init() {
        prepareHaptics()
    }

    func checkForStepOutliers(stepLength: Float) -> Bool {
        let difference = abs(targetStepLength - stepLength)
        return difference > 0.15
    }

    func checkForSpeedOutliers(speed: Float) -> Bool {
        let difference = abs(speedThreshold - speed)
        return difference > 0.2
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
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        
        let event = CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [intensity, sharpness],
                                  relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}

