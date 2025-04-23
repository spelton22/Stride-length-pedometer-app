////
////  StepChartView.swift
////  PedometerStepLengthApp
////
////  Created by Sophie Pelton on 4/16/25.
////
//
//import SwiftUI
//import Charts
//
//struct StepChartView: View {
//    @ObservedObject var stepTracker: StepTracker
//
//    var body: some View {
//        Chart {
//            ForEach(stepTracker.chartData) { data in
//                LineMark(
//                    x: .value("Step", data.stepIndex),
//                    y: .value("Z Accel", data.zAcceleration)
//                )
//                .foregroundStyle(.blue)
//                .symbol(by: .value("Type", "Z Accel"))
//
//                LineMark(
//                    x: .value("Step", data.stepIndex),
//                    y: .value("Time Interval", data.timeInterval)
//                )
//                .foregroundStyle(.orange)
//                .symbol(by: .value("Type", "Step Time"))
//            }
//        }
//        .chartLegend(.visible)
//        .chartYAxisLabel("Z Accel / Time Interval")
//        .chartXAxisLabel("Step Index")
//        .padding()
//    }
//}
