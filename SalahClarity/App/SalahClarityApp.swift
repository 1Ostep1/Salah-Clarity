//
//  SalahClarityApp.swift
//  Salah Clarity
//
//  App entry point. Sets up SwiftData, requests notification permissions,
//  and hosts the main TabView.
//

import SwiftUI
import SwiftData
import FirebaseCore
import UserNotifications

@main
struct SalahClarityApp: App {

    @StateObject private var localization = LocalizationManager.shared

    let modelContainer: ModelContainer = {
        let schema = Schema([
            QazaRecord.self,
            QazaCompletion.self,
            UserSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        FirebaseApp.configure()
        AnalyticsService.shared.logAppLaunch()
        requestNotificationAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
                .environment(\.locale, localization.locale)
                .environmentObject(localization)
                .id(localization.locale.identifier)
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                CrashReportingService.shared.record(error: error)
            }
            AnalyticsService.shared.log(event: "notification_permission", params: ["granted": "\(granted)"])
        }
    }
}
