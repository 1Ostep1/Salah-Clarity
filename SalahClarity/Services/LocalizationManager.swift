//
//  LocalizationManager.swift
//  Salah Clarity
//
//  Runtime language switching. Setting `language` here does two things:
//
//  1. Swaps the effective localization bundle so NSLocalizedString (used by
//     models/services that aren't SwiftUI Views) returns strings from the
//     chosen .lproj even without an app relaunch.
//  2. Publishes a new Locale so SwiftUI views that render LocalizedStringKey
//     (e.g. `Text("tab.prayer_times")`) re-evaluate their strings the moment
//     the user picks a different language in Settings.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class LocalizationManager: ObservableObject {

    static let shared = LocalizationManager()

    /// Published so SwiftUI re-renders when the user picks a new language.
    @Published private(set) var locale: Locale

    /// nil == follow system.
    private(set) var languageCode: String?

    private init() {
        // Read persisted choice (written by SettingsView). If none, follow the
        // system preference.
        let stored = UserDefaults.standard.string(forKey: Self.storageKey)
        self.languageCode = stored
        self.locale = Self.makeLocale(for: stored)
        Bundle.installLanguageSwizzle()
        Bundle.overrideLanguage = stored
    }

    /// Called by Settings when the user picks a language. Pass `nil` to
    /// follow the system.
    func setLanguage(_ code: String?) {
        languageCode = code
        UserDefaults.standard.set(code, forKey: Self.storageKey)
        // AppleLanguages also influences things like system date formatters.
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        Bundle.overrideLanguage = code
        locale = Self.makeLocale(for: code)
    }

    // MARK: - Helpers

    private static let storageKey = "SalahClarity.preferredLanguage"

    private static func makeLocale(for code: String?) -> Locale {
        if let code, !code.isEmpty {
            return Locale(identifier: code)
        }
        return Locale.autoupdatingCurrent
    }
}

// MARK: - Bundle swizzle

/// Swaps `localizedString(forKey:value:table:)` so NSLocalizedString picks up
/// the override language without an app relaunch.
private final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String,
                                  value: String?,
                                  table tableName: String?) -> String {
        if let code = Bundle.overrideLanguage,
           let path = Bundle.main.path(forResource: code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    fileprivate static var overrideLanguage: String?

    fileprivate static func installLanguageSwizzle() {
        // Changing Bundle.main's class to LocalizedBundle forces all
        // NSLocalizedString lookups through our override.
        guard object_getClass(Bundle.main) != LocalizedBundle.self else { return }
        object_setClass(Bundle.main, LocalizedBundle.self)
    }
}
