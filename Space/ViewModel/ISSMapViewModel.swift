//
//  ISSMapViewModel.swift
//  Space
//
//  Created by Ismail Mohammed on 2026-01-01.
//


import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class ISSMapViewModel: NSObject{
    private let service: ISSServicing = ISSService()
    private var pollingTask: Task<Void, Never>?
    
    private let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    
    var iss: ISSState?
    var errorMessage: String?
    var isFollowingISS: Bool = true
    
    override init() {
            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    
    func start() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        guard pollingTask == nil else { return }

        pollingTask = Task {
            while !Task.isCancelled {
                do {
                    let state = try await service.fetchISS()

                    iss = state
                    errorMessage = nil
                } catch {
                    errorMessage = error.localizedDescription
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    func getARPosition() -> (x: Float, y: Float, z: Float) {
            guard let iss = iss, let user = userLocation else {
                return (0, 0, -10)
            }
            
        return ISSARCalculator.calculatePosition(
                    userLocation: user,
                    issLatitude: iss.latitude,
                    issLongitude: iss.longitude,
                    issAltitudeKm: iss.altitude
                )
        }

    var coordinate: CLLocationCoordinate2D? {
        guard let iss else { return nil }
        return CLLocationCoordinate2D(latitude: iss.latitude, longitude: iss.longitude)
    }

    var altitudeText: String {
        guard let iss else { return "—" }
        return String(format: "%.0f km", iss.altitude)
    }

    var velocityText: String {
        guard let iss else { return "—" }
        return String(format: "%.0f km/h", iss.velocity)
    }

    var timestampText: String {
        guard let iss else { return "—" }
        let date = Date(timeIntervalSince1970: iss.timestamp)
        return date.formatted(date: .abbreviated, time: .standard)
    }
    
    
}

extension ISSMapViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "GPS: \(error.localizedDescription)"
    }
}
