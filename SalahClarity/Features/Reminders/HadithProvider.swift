//
//  HadithProvider.swift
//  Salah Clarity
//
//  Rotates through the bundled reminders by day-of-year so users see
//  one "hadith of the day" without internet access.
//

import Foundation

enum HadithProvider {

    /// Today's rotating hadith.
    static func dailyHadith(for date: Date = .now) -> Reminder {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let pool = Hadiths.hadiths
        return pool[day % pool.count]
    }

    /// Returns all reminders in a category, optionally filtered by a search query.
    static func reminders(for category: Reminder.Category,
                          matching query: String = "") -> [Reminder] {
        let base = Hadiths.byCategory(category)
        guard !query.isEmpty else { return base }
        let q = query.lowercased()
        return base.filter {
            $0.title.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }
}
