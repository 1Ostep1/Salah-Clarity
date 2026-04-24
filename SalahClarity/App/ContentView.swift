//
//  ContentView.swift
//  Salah Clarity
//
//  Root TabView — four primary features plus Settings.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: AppTab = .prayerTimes

    var body: some View {
        TabView(selection: $selectedTab) {
            PrayerTimesView()
                .tabItem {
                    Label("tab.prayer_times", systemImage: "sun.and.horizon.fill")
                }
                .tag(AppTab.prayerTimes)

            QazaView()
                .tabItem {
                    Label("tab.qaza", systemImage: "checkmark.circle.fill")
                }
                .tag(AppTab.qaza)

            QiblaView()
                .tabItem {
                    Label("tab.qibla", systemImage: "location.north.line.fill")
                }
                .tag(AppTab.qibla)

            RemindersView()
                .tabItem {
                    Label("tab.reminders", systemImage: "book.closed.fill")
                }
                .tag(AppTab.reminders)

            SettingsView()
                .tabItem {
                    Label("tab.settings", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
    }
}

enum AppTab: Hashable {
    case prayerTimes
    case qaza
    case qibla
    case reminders
    case settings
}

#Preview {
    ContentView()
        .modelContainer(for: [QazaRecord.self, QazaCompletion.self, UserSettings.self],
                        inMemory: true)
}
