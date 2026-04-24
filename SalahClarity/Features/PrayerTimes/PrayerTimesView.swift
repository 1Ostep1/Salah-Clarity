//
//  PrayerTimesView.swift
//  Salah Clarity
//

import SwiftUI
import SwiftData
import Combine
import CoreLocation

struct PrayerTimesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @State private var viewModel = PrayerTimesViewModel()
    @State private var locationManager = LocationManager.shared
    @State private var now: Date = .now

    private let tick = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        nextPrayerCard
                        prayerList
                    }
                    .padding()
                }
            }
            .navigationTitle("tab.prayer_times")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: setup)
        .onReceive(tick) { now = $0 }
        .onChange(of: locationManager.currentLocation) { _, _ in recompute() }
        .onChange(of: settings?.calculationMethodRaw) { _, _ in recompute() }
        .onChange(of: settings?.asrMethodRaw) { _, _ in recompute() }
        .onChange(of: settings?.tahajjudEnabled) { _, _ in recompute() }
    }

    // MARK: - Subviews

    private var headerCard: some View {
        VStack(spacing: 4) {
            Text(HijriDateFormatter.hijri(for: now))
                .font(Theme.titleFont(size: 18))
                .foregroundStyle(Theme.gold)
            Text(HijriDateFormatter.gregorian(for: now))
                .font(Theme.bodyFont())
                .foregroundStyle(Theme.textSecondary)
            if !viewModel.lastLocationName.isEmpty {
                Label(viewModel.lastLocationName, systemImage: "location.fill")
                    .font(Theme.bodyFont(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    @ViewBuilder
    private var nextPrayerCard: some View {
        if let countdown = viewModel.timeUntilNext(from: now) {
            VStack(spacing: 6) {
                Text("prayer_times.next")
                    .font(Theme.bodyFont(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Text(countdown.prayer.localizedName)
                    .font(Theme.displayFont(size: 48))
                    .foregroundStyle(Theme.gold)
                Text(String(format: NSLocalizedString("prayer_times.in", comment: ""),
                            countdown.remaining))
                    .font(Theme.bodyFont())
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .cardStyle()
        } else if locationManager.authorizationStatus == .notDetermined
                    || locationManager.authorizationStatus == .denied {
            locationPrompt
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
                .cardStyle()
        }
    }

    private var locationPrompt: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.slash")
                .font(.system(size: 32))
                .foregroundStyle(Theme.gold)
            Text("prayer_times.location_needed")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            Button {
                locationManager.requestAuthorization()
            } label: {
                Text("prayer_times.allow_location")
                    .font(Theme.bodyFont().weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.goldGradient)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .cardStyle()
    }

    @ViewBuilder
    private var prayerList: some View {
        if let times = viewModel.times {
            VStack(spacing: 0) {
                PrayerTimeRow(prayer: .fajr,    time: times.fajr,    now: now)
                divider
                PrayerTimeRow(prayer: .sunrise, time: times.sunrise, now: now, isInformational: true)
                divider
                PrayerTimeRow(prayer: .dhuhr,   time: times.dhuhr,   now: now)
                divider
                PrayerTimeRow(prayer: .asr,     time: times.asr,     now: now)
                divider
                PrayerTimeRow(prayer: .maghrib, time: times.maghrib, now: now)
                divider
                PrayerTimeRow(prayer: .isha,    time: times.isha,    now: now)
                if let tahajjud = viewModel.tahajjudStart {
                    divider
                    PrayerTimeRow(prayer: .tahajjud,
                                  time: tahajjud,
                                  now: now,
                                  isInformational: true)
                }
            }
            .cardStyle()
        }
    }

    private var divider: some View {
        Divider().overlay(Theme.gold.opacity(0.1))
    }

    // MARK: - Lifecycle

    private func setup() {
        ensureSettingsExist()
        locationManager.requestAuthorization()
        locationManager.startUpdates()
        recompute()
    }

    private func ensureSettingsExist() {
        if settingsList.isEmpty {
            modelContext.insert(UserSettings())
            try? modelContext.save()
        }
    }

    private func recompute() {
        viewModel.recalculate(for: now,
                              settings: settings,
                              location: locationManager.currentLocation)
    }
}

// MARK: - Row

struct PrayerTimeRow: View {
    let prayer: Prayer
    let time: Date
    let now: Date
    var isInformational: Bool = false

    private var isCurrent: Bool {
        // "Current" = we're within the window this prayer is active.
        // Simple heuristic: within 30 minutes before or until the next prayer time.
        abs(time.timeIntervalSince(now)) < 60 * 30 && time <= now
    }

    private var timeString: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: time)
    }

    var body: some View {
        HStack {
            Image(systemName: prayer.symbolName)
                .font(.system(size: 18))
                .foregroundStyle(isInformational ? Theme.textSecondary : Theme.gold)
                .frame(width: 28)

            Text(prayer.localizedName)
                .font(Theme.bodyFont(size: 17))
                .foregroundStyle(isInformational ? Theme.textSecondary : .white)

            Spacer()

            Text(timeString)
                .font(.system(size: 17, weight: .medium, design: .monospaced))
                .foregroundStyle(isCurrent ? Theme.gold : (isInformational ? Theme.textSecondary : .white))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
    }
}

#Preview {
    PrayerTimesView()
        .modelContainer(for: [QazaRecord.self, QazaCompletion.self, UserSettings.self],
                        inMemory: true)
}
