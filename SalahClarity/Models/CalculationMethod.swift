//
//  CalculationMethod.swift
//  Salah Clarity
//
//  Fajr / Isha twilight angles for the major calculation methods.
//  Values are the standard angles used by IslamicFinder / Adhan.
//

import Foundation

enum CalculationMethod: String, CaseIterable, Identifiable, Codable {
    case mwl       // Muslim World League
    case isna      // Islamic Society of North America
    case egypt     // Egyptian General Authority of Survey
    case makkah    // Umm al-Qura University, Makkah
    case karachi   // University of Islamic Sciences, Karachi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mwl:     return "Muslim World League"
        case .isna:    return "ISNA"
        case .egypt:   return "Egypt"
        case .makkah:  return "Umm al-Qura (Makkah)"
        case .karachi: return "Karachi"
        }
    }

    /// Angle (in degrees below horizon) used for Fajr.
    var fajrAngle: Double {
        switch self {
        case .mwl:     return 18.0
        case .isna:    return 15.0
        case .egypt:   return 19.5
        case .makkah:  return 18.5
        case .karachi: return 18.0
        }
    }

    /// Angle (in degrees below horizon) used for Isha.
    /// If `nil`, Isha is a fixed offset from Maghrib (used by Makkah method).
    var ishaAngle: Double? {
        switch self {
        case .mwl:     return 17.0
        case .isna:    return 15.0
        case .egypt:   return 17.5
        case .makkah:  return nil          // fixed offset
        case .karachi: return 18.0
        }
    }

    /// Minutes after Maghrib when no Isha angle is defined.
    /// Makkah uses 90 minutes (120 during Ramadan — app-level toggle TODO).
    var ishaMinutesAfterMaghrib: Int { 90 }
}

/// Asr shadow calculation.
enum AsrMethod: String, CaseIterable, Identifiable, Codable {
    case standard   // Shafi / Maliki / Hanbali — shadow = 1x object length
    case hanafi     // Hanafi — shadow = 2x object length

    var id: String { rawValue }

    var shadowFactor: Double {
        switch self {
        case .standard: return 1.0
        case .hanafi:   return 2.0
        }
    }

    var displayName: String {
        switch self {
        case .standard: return NSLocalizedString("settings.asr_standard", comment: "")
        case .hanafi:   return NSLocalizedString("settings.asr_hanafi", comment: "")
        }
    }
}
