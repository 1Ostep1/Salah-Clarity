//
//  PrayerCalculator.swift
//  Salah Clarity
//
//  Standalone astronomical prayer-time calculator.
//  Based on the algorithm documented by the University of Islamic Sciences,
//  Karachi and used by most open-source libraries (PrayTimes.org, Adhan-swift).
//
//  For production accuracy with high-latitude edge cases, swap this out for
//  the Adhan Swift library — the public surface (`times(for:...)`) makes the
//  replacement trivial.
//

import Foundation
import CoreLocation

struct PrayerCalculator {

    struct Times {
        var fajr:    Date
        var sunrise: Date
        var dhuhr:   Date
        var asr:     Date
        var maghrib: Date
        var isha:    Date

        func time(for prayer: Prayer) -> Date {
            switch prayer {
            case .fajr:     return fajr
            case .sunrise:  return sunrise
            case .dhuhr:    return dhuhr
            case .asr:      return asr
            case .maghrib:  return maghrib
            case .isha:     return isha
            case .tahajjud: return isha // caller should use `tahajjudStart(fajrTomorrow:)` instead
            }
        }

        /// The next prayer from a given reference date.
        /// Returns `nil` if all of today's prayers have passed — caller should
        /// roll over to tomorrow's Fajr.
        func nextPrayer(after date: Date = .now) -> (prayer: Prayer, time: Date)? {
            let ordered: [(Prayer, Date)] = [
                (.fajr, fajr), (.dhuhr, dhuhr), (.asr, asr),
                (.maghrib, maghrib), (.isha, isha)
            ]
            return ordered.first { $0.1 > date }
        }

        /// Start of the last third of the night — the most virtuous time for
        /// Tahajjud. Night = from Isha to next-day Fajr. Last third starts at
        /// Isha + (2/3) × night length.
        func tahajjudStart(fajrTomorrow: Date) -> Date {
            let nightLength = fajrTomorrow.timeIntervalSince(isha)
            return isha.addingTimeInterval(nightLength * 2.0 / 3.0)
        }
    }

    // MARK: - Public API

    static func times(
        for date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone,
        method: CalculationMethod,
        asrMethod: AsrMethod
    ) -> Times {

        let jd = julianDay(for: date, timeZone: timeZone)
        let sun = sunPosition(julianDay: jd)

        let tzOffsetHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let lat = coordinate.latitude
        let lng = coordinate.longitude

        // Solar noon (in hours, local time)
        let dhuhrHours = 12.0 + tzOffsetHours - lng / 15.0 - sun.equationOfTime / 60.0

        // Sunrise / sunset use the standard -0.833° (refraction + solar radius).
        let sunriseHours = dhuhrHours - hourAngle(angle: 0.833, latitude: lat, declination: sun.declination)
        let maghribHours = dhuhrHours + hourAngle(angle: 0.833, latitude: lat, declination: sun.declination)

        // Fajr / Isha (twilight angles)
        let fajrHours = dhuhrHours - hourAngle(angle: method.fajrAngle,
                                               latitude: lat,
                                               declination: sun.declination)

        let ishaHours: Double
        if let angle = method.ishaAngle {
            ishaHours = dhuhrHours + hourAngle(angle: angle,
                                               latitude: lat,
                                               declination: sun.declination)
        } else {
            ishaHours = maghribHours + Double(method.ishaMinutesAfterMaghrib) / 60.0
        }

        // Asr
        let asrAngleDeg = -atan2(1.0,
                                 asrMethod.shadowFactor + tan(radians(abs(lat - sun.declination))))
            .degrees
        let asrHours = dhuhrHours + hourAngle(angle: asrAngleDeg,
                                              latitude: lat,
                                              declination: sun.declination)

        return Times(
            fajr:    date.setting(hoursFromMidnight: fajrHours,    timeZone: timeZone),
            sunrise: date.setting(hoursFromMidnight: sunriseHours, timeZone: timeZone),
            dhuhr:   date.setting(hoursFromMidnight: dhuhrHours,   timeZone: timeZone),
            asr:     date.setting(hoursFromMidnight: asrHours,     timeZone: timeZone),
            maghrib: date.setting(hoursFromMidnight: maghribHours, timeZone: timeZone),
            isha:    date.setting(hoursFromMidnight: ishaHours,    timeZone: timeZone)
        )
    }

    // MARK: - Astronomy helpers

    /// Sun declination (degrees) + equation of time (minutes).
    private static func sunPosition(julianDay jd: Double) -> (declination: Double, equationOfTime: Double) {
        let d = jd - 2451545.0 // days since J2000.0
        let g = normalize(degrees: 357.529 + 0.98560028 * d)
        let q = normalize(degrees: 280.459 + 0.98564736 * d)
        let L = normalize(degrees: q + 1.915 * sin(radians(g)) + 0.020 * sin(radians(2.0 * g)))

        // Obliquity of the ecliptic
        let e = 23.439 - 0.00000036 * d

        // Right ascension (in hours) via atan2, normalized to [0, 24)
        let RA_hours = normalize(hours: atan2(cos(radians(e)) * sin(radians(L)),
                                              cos(radians(L))).degrees / 15.0)

        let declination = asin(sin(radians(e)) * sin(radians(L))).degrees
        let equationOfTime = (q / 15.0 - RA_hours) * 60.0  // minutes
        return (declination, equationOfTime)
    }

    /// Hour angle (hours) for the sun reaching a given `angle` below horizon.
    private static func hourAngle(angle: Double, latitude: Double, declination: Double) -> Double {
        let num = -sin(radians(angle)) - sin(radians(latitude)) * sin(radians(declination))
        let den = cos(radians(latitude)) * cos(radians(declination))
        let ratio = max(-1.0, min(1.0, num / den))
        return acos(ratio).degrees / 15.0
    }

    private static func julianDay(for date: Date, timeZone: TimeZone) -> Double {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        var Y = Double(comps.year ?? 2026)
        var M = Double(comps.month ?? 1)
        let D = Double(comps.day ?? 1)

        if M <= 2 { Y -= 1; M += 12 }
        let A = floor(Y / 100.0)
        let B = 2 - A + floor(A / 4.0)
        return floor(365.25 * (Y + 4716)) + floor(30.6001 * (M + 1)) + D + B - 1524.5
    }

    // MARK: - Math utilities

    private static func radians(_ deg: Double) -> Double { deg * .pi / 180.0 }

    private static func normalize(degrees: Double) -> Double {
        let r = degrees.truncatingRemainder(dividingBy: 360.0)
        return r < 0 ? r + 360.0 : r
    }

    private static func normalize(hours: Double) -> Double {
        let r = hours.truncatingRemainder(dividingBy: 24.0)
        return r < 0 ? r + 24.0 : r
    }
}

// MARK: - Helpers

private extension Double {
    var degrees: Double { self * 180.0 / .pi }
}

private extension Date {
    /// Returns a new date on the same calendar day at `hoursFromMidnight` local time.
    func setting(hoursFromMidnight hours: Double, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: self)
        return start.addingTimeInterval(hours * 3600.0)
    }
}
