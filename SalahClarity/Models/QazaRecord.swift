//
//  QazaRecord.swift
//  Salah Clarity
//
//  One record per prayer-type, tracking how many the user owes
//  and the daily goal for paying them back.
//

import Foundation
import SwiftData

@Model
final class QazaRecord {
    /// Stored as the raw value of `Prayer` — SwiftData can't index enums directly.
    @Attribute(.unique) var prayerRawValue: String

    /// Total number the user originally owed (snapshot when set / bumped).
    var totalOwed: Int

    /// Number already completed (running sum of linked `QazaCompletion`s).
    var completed: Int

    /// Daily goal — defaults to 1 extra prayer per day.
    var dailyGoal: Int

    /// When the record was first created.
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \QazaCompletion.record)
    var completions: [QazaCompletion] = []

    init(prayer: Prayer,
         totalOwed: Int,
         dailyGoal: Int = 1,
         completed: Int = 0,
         createdAt: Date = .now)
    {
        self.prayerRawValue = prayer.rawValue
        self.totalOwed = totalOwed
        self.completed = completed
        self.dailyGoal = dailyGoal
        self.createdAt = createdAt
    }

    var prayer: Prayer {
        Prayer(rawValue: prayerRawValue) ?? .fajr
    }

    var remaining: Int {
        max(0, totalOwed - completed)
    }

    var progressFraction: Double {
        guard totalOwed > 0 else { return 0 }
        return min(1.0, Double(completed) / Double(totalOwed))
    }

    /// Consecutive days (up to today) on which the daily goal was met.
    var currentStreak: Int {
        let calendar = Calendar.current
        // Bucket completions by day.
        let byDay = Dictionary(grouping: completions) {
            calendar.startOfDay(for: $0.date)
        }
        var streak = 0
        var day = calendar.startOfDay(for: .now)
        while let entries = byDay[day], entries.count >= dailyGoal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}
