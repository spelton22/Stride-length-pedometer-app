//
//  LocationManager.swift
//  PedometerStepLengthApp
//
//  Created by Sophie Pelton on 4/30/25.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    
    @Published var totalDistance: Double = 0.0
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func start() {
        totalDistance = 0
        lastLocation = nil
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        if let last = lastLocation {
            let delta = newLocation.distance(from: last) // meters
            totalDistance += delta
        }
        
        lastLocation = newLocation
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func pause() {
        locationManager.stopUpdatingLocation()
    }

    func resume() {
        locationManager.startUpdatingLocation()
    }
}
