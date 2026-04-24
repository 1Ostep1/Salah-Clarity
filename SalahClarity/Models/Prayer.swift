//
//  Prayer.swift
//  Salah Clarity
//

import Foundation

/// The five obligatory daily prayers plus sunrise (used as a reference point).
enum Prayer: String, CaseIterable, Identifiable, Codable, Hashable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha
    /// Voluntary night prayer — not part of the daily five, shown only if the
    /// user has enabled the Tahajjud reminder in Settings.
    case tahajjud

    var id: String { rawValue }

    /// Only the five farḍ prayers — sunrise and tahajjud excluded.
    static var obligatory: [Prayer] { [.fajr, .dhuhr, .asr, .maghrib, .isha] }

    var localizedName: String {
        NSLocalizedString("prayer.\(rawValue)", comment: "")
    }

    var symbolName: String {
        switch self {
        case .fajr:     return "sunrise.fill"
        case .sunrise:  return "sun.max.fill"
        case .dhuhr:    return "sun.max"
        case .asr:      return "sun.haze.fill"
        case .maghrib:  return "sunset.fill"
        case .isha:     return "moon.stars.fill"
        case .tahajjud: return "moon.zzz.fill"
        }
    }
}
