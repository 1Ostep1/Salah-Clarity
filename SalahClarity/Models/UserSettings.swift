//
//  UserSettings.swift
//  Salah Clarity
//
//  Single-row SwiftData model for heavier preferences.
//  Lightweight toggles (reminder on/off, etc.) use @AppStorage instead.
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var calculationMethodRaw: String
    var asrMethodRaw: String
    var notificationsEnabled: Bool
    var adhanSoundEnabled: Bool
    var preferredLanguageCode: String?   // nil → follow system
    /// When on, the Prayer Times screen shows the last-third-of-the-night
    /// Tahajjud row and a reminder notification is scheduled at that time.
    /// Default value set here so existing stores migrate without a schema bump.
    var tahajjudEnabled: Bool = false

    init(calculationMethod: CalculationMethod = .mwl,
         asrMethod: AsrMethod = .standard,
         notificationsEnabled: Bool = true,
         adhanSoundEnabled: Bool = true,
         preferredLanguageCode: String? = nil,
         tahajjudEnabled: Bool = false)
    {
        self.calculationMethodRaw = calculationMethod.rawValue
        self.asrMethodRaw = asrMethod.rawValue
        self.notificationsEnabled = notificationsEnabled
        self.adhanSoundEnabled = adhanSoundEnabled
        self.preferredLanguageCode = preferredLanguageCode
        self.tahajjudEnabled = tahajjudEnabled
    }

    var calculationMethod: CalculationMethod {
        get { CalculationMethod(rawValue: calculationMethodRaw) ?? .mwl }
        set { calculationMethodRaw = newValue.rawValue }
    }

    var asrMethod: AsrMethod {
        get { AsrMethod(rawValue: asrMethodRaw) ?? .standard }
        set { asrMethodRaw = newValue.rawValue }
    }
}
