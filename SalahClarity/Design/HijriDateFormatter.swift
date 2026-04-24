//
//  HijriDateFormatter.swift
//  Salah Clarity
//
//  Shows the current Hijri (Islamic) date alongside the Gregorian.
//  Uses Foundation's built-in `islamicUmmAlQura` calendar.
//

import Foundation

enum HijriDateFormatter {

    private static let hijriFormatter: DateFormatter = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale.current
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale.current
        f.dateStyle = .long
        return f
    }()

    private static let gregorianFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.dateStyle = .full
        return f
    }()

    /// e.g. "15 Shawwal 1447 AH"
    static func hijri(for date: Date = .now) -> String {
        hijriFormatter.string(from: date)
    }

    /// e.g. "Thursday, April 23, 2026"
    static func gregorian(for date: Date = .now) -> String {
        gregorianFormatter.string(from: date)
    }
}
