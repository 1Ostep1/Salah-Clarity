//
//  QiblaViewModel.swift
//  Salah Clarity
//
//  Great-circle bearing + distance from the user's coordinate to the Kaaba.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class QiblaViewModel {

    /// Kaaba coordinates (well-known constants).
    static let kaaba = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    /// Bearing to Makkah, in degrees from true north (0..<360).
    var bearing: Double = 0
    /// Distance in kilometers.
    var distanceKm: Double = 0

    func update(from location: CLLocation) {
        let lat1 = radians(location.coordinate.latitude)
        let lat2 = radians(Self.kaaba.latitude)
        let deltaLng = radians(Self.kaaba.longitude - location.coordinate.longitude)

        let y = sin(deltaLng) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLng)
        var deg = degrees(atan2(y, x))
        if deg < 0 { deg += 360 }
        bearing = deg

        let kaabaLoc = CLLocation(latitude: Self.kaaba.latitude, longitude: Self.kaaba.longitude)
        distanceKm = location.distance(from: kaabaLoc) / 1000.0
    }

    private func radians(_ deg: Double) -> Double { deg * .pi / 180.0 }
    private func degrees(_ rad: Double) -> Double { rad * 180.0 / .pi }
}
