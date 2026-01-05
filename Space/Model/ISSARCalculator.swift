//
//  ISSARCalculator.swift
//  Space
//
//  Created by Milan Hatami on 2026-01-05.
//

import Foundation
import CoreLocation

struct ISSARCalculator {
    
  
    static func calculatePosition(
        userLocation: CLLocation,
        issLatitude: Double,
        issLongitude: Double,
        issAltitudeKm: Double
    ) -> (x: Float, y: Float, z: Float) {
        
        // 1. Konvertera grader till radianer
        let userLat = userLocation.coordinate.latitude * .pi / 180
        let userLon = userLocation.coordinate.longitude * .pi / 180
        let issLatRad = issLatitude * .pi / 180
        let issLonRad = issLongitude * .pi / 180
        
        // 2. Beräkna bäring (Azimuth) - Riktning i sidled
        let dLon = issLonRad - userLon
        let y = sin(dLon) * cos(issLatRad)
        let x = cos(userLat) * sin(issLatRad) - sin(userLat) * cos(issLatRad) * cos(dLon)
        let bearing = atan2(y, x)
        
        // 3. Beräkna elevation (Altitude) - Vinkel uppåt
        let issLocation = CLLocation(latitude: issLatitude, longitude: issLongitude)
        let distanceInKm = userLocation.distance(from: issLocation) / 1000
        let elevation = atan2(issAltitudeKm, distanceInKm)
        
        // 4. Konvertera sfäriska koordinater till Kartesiska (X, Y, Z) för AR
        // Vi använder en radie på 100 meter (ändra här för att justera avståndet visuellt)
        let radius: Float = 100.0
        
        let arX = radius * Float(cos(elevation)) * Float(sin(bearing))
        let arY = radius * Float(sin(elevation))
        let arZ = -radius * Float(cos(elevation)) * Float(cos(bearing))
        
        return (arX, arY, arZ)
    }
}
