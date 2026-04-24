//
//  NotificationScheduler.swift
//  Salah Clarity
//
//  Schedules local notifications for the next 7 days of prayer times and
//  an optional daily "Hadith of the day" reminder.
//

import Foundation
import UserNotifications
import CoreLocation

final class NotificationScheduler {

    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let dailyHadithIdentifier = "daily-hadith"

    /// Filename of the custom azan audio bundled in the app. Must live at
    /// the **top level** of the app bundle (NOT inside a subfolder) and be
    /// ≤ 30 seconds long — iOS silently falls back otherwise. See
    /// `Resources/Sounds/README.md` for placement rules.
    private let azanFileName = "azan.caf"

    /// True if a file named `azan.caf` is present at the bundle root.
    /// Used by the test-notification button to surface a clear error
    /// instead of the user wondering why nothing plays.
    var isAzanBundled: Bool {
        Bundle.main.url(forResource: "azan", withExtension: "caf") != nil
    }

    /// Sound used for fard-prayer notifications. Falls back to the default
    /// system sound if `azan.caf` isn't bundled at the root, so we never
    /// send a silent notification by accident.
    private var prayerSound: UNNotificationSound {
        if isAzanBundled {
            return UNNotificationSound(
                named: UNNotificationSoundName(rawValue: azanFileName)
            )
        }
        return .default
    }

    // MARK: - Prayers

    /// Recomputes and schedules 7 days of prayer notifications.
    /// Call this on app foreground and when settings/location change.
    func reschedule(using settings: UserSettings) {
        guard settings.notificationsEnabled,
              let location = LocationManager.shared.currentLocation else {
            // Cancel any existing prayer + tahajjud notifications.
            center.getPendingNotificationRequests { requests in
                let ids = requests.map(\.identifier)
                    .filter { $0.hasPrefix("prayer-") || $0.hasPrefix("tahajjud-") }
                self.center.removePendingNotificationRequests(withIdentifiers: ids)
            }
            return
        }

        Task {
            await scheduleNextWeek(from: location.coordinate,
                                   settings: settings)
        }
    }

    private func scheduleNextWeek(from coordinate: CLLocationCoordinate2D,
                                  settings: UserSettings) async {
        // Clear previous prayer + tahajjud notifications.
        let pending = await center.pendingNotificationRequests()
        let staleIDs = pending.map(\.identifier)
            .filter { $0.hasPrefix("prayer-") || $0.hasPrefix("tahajjud-") }
        center.removePendingNotificationRequests(withIdentifiers: staleIDs)

        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let times = PrayerCalculator.times(
                for: day,
                coordinate: coordinate,
                timeZone: .current,
                method: settings.calculationMethod,
                asrMethod: settings.asrMethod
            )

            // The five obligatory prayers — these get the azan tone when
            // the user has adhan sound enabled.
            for prayer in Prayer.obligatory {
                let date = times.time(for: prayer)
                guard date > now else { continue }
                schedulePrayer(prayer,
                               at: date,
                               withAzan: settings.adhanSoundEnabled)
            }

            // Tahajjud reminder — voluntary, default sound only.
            if settings.tahajjudEnabled,
               let tomorrow = calendar.date(byAdding: .day, value: 1, to: day) {
                let tomorrowTimes = PrayerCalculator.times(
                    for: tomorrow,
                    coordinate: coordinate,
                    timeZone: .current,
                    method: settings.calculationMethod,
                    asrMethod: settings.asrMethod
                )
                let tahajjudAt = times.tahajjudStart(fajrTomorrow: tomorrowTimes.fajr)
                if tahajjudAt > now {
                    scheduleTahajjud(at: tahajjudAt)
                }
            }
        }
    }

    /// Schedules a single prayer-time notification. Fard prayers get the
    /// custom azan sound when `withAzan` is true; other prayers stay silent
    /// or use the default notification sound.
    private func schedulePrayer(_ prayer: Prayer,
                                at date: Date,
                                withAzan: Bool) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = prayer.localizedName
        content.body = NSLocalizedString("prayer_times.next", comment: "")

        // Azan only for the 5 fard prayers — even if somehow a non-obligatory
        // prayer lands here, fall back to the default sound.
        if withAzan && Prayer.obligatory.contains(prayer) {
            content.sound = prayerSound
        } else {
            content.sound = withAzan ? .default : nil
        }

        let id = "prayer-\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                CrashReportingService.shared.record(error: error)
            }
        }
    }

    private func scheduleTahajjud(at date: Date) {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("prayer.tahajjud", comment: "")
        content.body = NSLocalizedString("settings.tahajjud_note", comment: "")
        content.sound = .default // voluntary — no azan

        let id = "tahajjud-\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error {
                CrashReportingService.shared.record(error: error)
            }
        }
    }

    // MARK: - Daily hadith

    /// Schedule a 08:00 daily reminder that pulls today's hadith.
    func scheduleDailyHadith(hour: Int = 8, minute: Int = 0) {
        cancelDailyHadith()

        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("reminders.daily_hadith", comment: "")
        content.body = HadithProvider.dailyHadith().body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: dailyHadithIdentifier,
                                            content: content,
                                            trigger: trigger)
        center.add(request)
    }

    func cancelDailyHadith() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyHadithIdentifier])
    }

    // MARK: - Diagnostics

    /// Result of the test-notification flow so Settings can show an
    /// actionable alert instead of silently failing.
    enum TestResult {
        case scheduled(usedAzan: Bool)
        case needsPermission
    }

    /// Fires a single local notification ~5 seconds from now. Tries the
    /// azan sound first; if `azan.caf` isn't at the bundle root the
    /// notification still fires (with the default system sound) and the
    /// completion reports `usedAzan: false` so the UI can explain why.
    func sendTestNotification(completion: @escaping (TestResult) -> Void) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            let status = settings.authorizationStatus
            guard status == .authorized || status == .provisional else {
                DispatchQueue.main.async { completion(.needsPermission) }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.test_title", comment: "")
            content.body  = NSLocalizedString("notification.test_body",  comment: "")
            content.sound = self.prayerSound

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "test-\(UUID().uuidString)",
                                                content: content,
                                                trigger: trigger)
            let usedAzan = self.isAzanBundled
            self.center.add(request) { error in
                if let error {
                    CrashReportingService.shared.record(error: error)
                }
                DispatchQueue.main.async {
                    completion(.scheduled(usedAzan: usedAzan))
                }
            }
        }
    }
}
