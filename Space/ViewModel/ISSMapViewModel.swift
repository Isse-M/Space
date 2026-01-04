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
            // Om vi saknar data, placera den 10m bort som fallback
            guard let iss = iss, let user = userLocation else {
                return (0, 0, -10)
            }
            
            // 1. Konvertera grader till radianer
            let userLat = user.coordinate.latitude * .pi / 180
            let userLon = user.coordinate.longitude * .pi / 180
            let issLat = iss.latitude * .pi / 180
            let issLon = iss.longitude * .pi / 180
            
            // 2. Beräkna bäring (riktning i grader på kompassen)
            let dLon = issLon - userLon
            let y = sin(dLon) * cos(issLat)
            let x = cos(userLat) * sin(issLat) - sin(userLat) * cos(issLat) * cos(dLon)
            let bearing = atan2(y, x)
            
            // 3. Beräkna elevation (vinkel upp mot rymden)
            let distanceInKm = user.distance(from: CLLocation(latitude: iss.latitude, longitude: iss.longitude)) / 1000
            let elevation = atan2(iss.altitude, distanceInKm)
            
            // 4. Omvandla till AR-koordinater
            // Vi använder en virtuell radie på 50 meter för visualisering
            let radius: Float = 50.0
            
            let arX = radius * Float(cos(elevation)) * Float(sin(bearing))
            let arY = radius * Float(sin(elevation))
            let arZ = -radius * Float(cos(elevation)) * Float(cos(bearing))
            
            return (arX, arY, arZ)
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
