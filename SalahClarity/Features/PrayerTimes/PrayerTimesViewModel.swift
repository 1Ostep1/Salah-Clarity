//
//  PrayerTimesViewModel.swift
//  Salah Clarity
//

import Foundation
import CoreLocation
import Observation
import SwiftData

@Observable
final class PrayerTimesViewModel {

    var times: PrayerCalculator.Times?
    var lastLocationName: String = ""
    /// Start of the last third of the night — computed only when Tahajjud
    /// is enabled in Settings. Nil otherwise so the row hides cleanly.
    var tahajjudStart: Date?

    private let geocoder = CLGeocoder()

    /// Recompute prayer times for `date` using the current location and settings.
    func recalculate(for date: Date = .now,
                     settings: UserSettings?,
                     location: CLLocation?) {
        guard let location else { return }
        let method = settings?.calculationMethod ?? .mwl
        let asr = settings?.asrMethod ?? .standard

        let today = PrayerCalculator.times(
            for: date,
            coordinate: location.coordinate,
            timeZone: .current,
            method: method,
            asrMethod: asr
        )
        times = today

        // Tahajjud: we need tomorrow's Fajr to know the night's length.
        if settings?.tahajjudEnabled == true,
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) {
            let next = PrayerCalculator.times(
                for: tomorrow,
                coordinate: location.coordinate,
                timeZone: .current,
                method: method,
                asrMethod: asr
            )
            tahajjudStart = today.tahajjudStart(fajrTomorrow: next.fajr)
        } else {
            tahajjudStart = nil
        }

        // Lazy reverse-geocode so we can show the city name.
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let name = placemarks?.first?.locality {
                Task { @MainActor in
                    self?.lastLocationName = name
                }
            }
        }
    }

    /// "in 1 h 12 min" style countdown to the next prayer.
    func timeUntilNext(from date: Date = .now) -> (prayer: Prayer, remaining: String)? {
        guard let times else { return nil }
        let next: (prayer: Prayer, time: Date)
        if let found = times.nextPrayer(after: date) {
            next = found
        } else {
            // All of today's prayers have passed — point to tomorrow's Fajr.
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            next = (.fajr, times.fajr.addingTimeInterval(
                tomorrow.timeIntervalSince(date).rounded() > 0 ? 86_400 : 0))
        }

        let interval = next.time.timeIntervalSince(date)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return (next.prayer, formatter.string(from: interval) ?? "—")
    }
}
