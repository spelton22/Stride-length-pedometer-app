//
//  CalibrationInProgressView.swift
//  PedometerStepLengthApp
//
//  Created by Sophie Pelton on 4/8/25.
//

import SwiftUI

struct CalibrationInProgressView: View {
    @ObservedObject var stepManager: StepManager
    @ObservedObject var stepTracker: StepTracker
    @Environment(\.dismiss) var dismiss

    @State private var stepsTaken: Int = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("Calibration in Progress")
                .font(.largeTitle)
                .bold()

            Text("Steps Taken: \(stepManager.stepCount)")
                .font(.title2)
                .foregroundColor(.blue)

            Button("Stop Calibration") {
                stopCalibration()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .onAppear {
            // Start tracking when this view appears
            stepTracker.startTracking()
        }
    }

    private func stopCalibration() {
        // Stop step tracking and return to the calibration page
        stepTracker.stopTracking()
        dismiss()  // Go back to the CalibrationView
    }
}
