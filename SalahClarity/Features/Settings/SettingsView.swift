//
//  SettingsView.swift
//  Salah Clarity
//

import SwiftUI
import SwiftData
import StoreKit
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localization: LocalizationManager
    @Query private var settingsList: [UserSettings]
    @AppStorage("dailyHadithNotificationEnabled") private var dailyHadithEnabled: Bool = false

    @State private var tipJar = TipJarService.shared
    @State private var thanksShown = false
    @State private var testNotificationBanner: TestBanner?

    /// Transient banner for feedback after a user taps "Send test notification".
    private enum TestBanner: Identifiable {
        case scheduledWithAzan
        case scheduledWithoutAzan
        case needsPermission
        var id: String {
            switch self {
            case .scheduledWithAzan:    return "ok-azan"
            case .scheduledWithoutAzan: return "ok-no-azan"
            case .needsPermission:      return "no-permission"
            }
        }
    }

    private var settings: UserSettings {
        if let s = settingsList.first { return s }
        let s = UserSettings()
        modelContext.insert(s)
        try? modelContext.save()
        return s
    }

    var body: some View {
        NavigationStack {
            Form {
                calculationSection
                notificationsSection
                languageSection
//                tipJarSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("settings.title")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Jazak Allah khayran 🤲", isPresented: $thanksShown) {
                Button("OK", role: .cancel) { }
            }
            .alert(item: $testNotificationBanner) { banner in
                switch banner {
                case .scheduledWithAzan:
                    return Alert(
                        title: Text("settings.test_notification"),
                        message: Text("Notification scheduled in 5 seconds with the azan sound. Lock your phone to hear it."),
                        dismissButton: .default(Text("OK"))
                    )
                case .scheduledWithoutAzan:
                    return Alert(
                        title: Text("settings.test_notification"),
                        message: Text("Notification scheduled — but azan.caf wasn't found at the app bundle root, so the default iOS chime will play instead. See Resources/Sounds/README.md."),
                        dismissButton: .default(Text("OK"))
                    )
                case .needsPermission:
                    return Alert(
                        title: Text("settings.notifications"),
                        message: Text("Enable notifications for Salah Clarity in iOS Settings."),
                        primaryButton: .default(Text("Open Settings")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var calculationSection: some View {
        Section("settings.calc_method") {
            Picker("settings.calc_method", selection: Binding(
                get: { settings.calculationMethod },
                set: { settings.calculationMethod = $0; try? modelContext.save() }
            )) {
                ForEach(CalculationMethod.allCases) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .pickerStyle(.navigationLink)
        }

        Section("settings.asr_method") {
            Picker("settings.asr_method", selection: Binding(
                get: { settings.asrMethod },
                set: { settings.asrMethod = $0; try? modelContext.save() }
            )) {
                ForEach(AsrMethod.allCases) { m in
                    Text(m.displayName).tag(m)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var notificationsSection: some View {
        Section("settings.notifications") {
            Toggle("settings.notifications", isOn: Binding(
                get: { settings.notificationsEnabled },
                set: {
                    settings.notificationsEnabled = $0
                    try? modelContext.save()
                    NotificationScheduler.shared.reschedule(using: settings)
                }
            ))
            Toggle("settings.adhan_sound", isOn: Binding(
                get: { settings.adhanSoundEnabled },
                set: {
                    settings.adhanSoundEnabled = $0
                    try? modelContext.save()
                    NotificationScheduler.shared.reschedule(using: settings)
                }
            ))
            Toggle("reminders.daily_hadith", isOn: $dailyHadithEnabled)
                .onChange(of: dailyHadithEnabled) { _, newValue in
                    if newValue {
                        NotificationScheduler.shared.scheduleDailyHadith()
                    } else {
                        NotificationScheduler.shared.cancelDailyHadith()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("settings.tahajjud", isOn: Binding(
                    get: { settings.tahajjudEnabled },
                    set: {
                        settings.tahajjudEnabled = $0
                        try? modelContext.save()
                        NotificationScheduler.shared.reschedule(using: settings)
                    }
                ))
                Text("settings.tahajjud_note")
                    .font(Theme.bodyFont(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var languageSection: some View {
        Section("settings.language") {
            Picker("settings.language", selection: Binding(
                get: { settings.preferredLanguageCode ?? "system" },
                set: { newValue in
                    let code: String? = (newValue == "system") ? nil : newValue
                    settings.preferredLanguageCode = code
                    try? modelContext.save()
                    // Apply immediately — LocalizationManager publishes a new
                    // locale which re-renders the whole view tree.
                    localization.setLanguage(code)
                }
            )) {
                Text("System").tag("system")
                Text("English").tag("en")
                Text("Русский").tag("ru")
                Text("Кыргызча").tag("ky")
            }
        }
    }

    @ViewBuilder
    private var tipJarSection: some View {
        Section("settings.tip_jar") {
            if tipJar.products.isEmpty {
                // Stub buttons shown until real StoreKit product IDs are configured.
                Button("settings.tip_small") { showThanks() }
                Button("settings.tip_medium") { showThanks() }
            } else {
                ForEach(tipJar.products, id: \.id) { product in
                    Button {
                        Task {
                            if await tipJar.purchase(product) {
                                showThanks()
                            }
                        }
                    } label: {
                        HStack {
                            Text(product.displayName)
                            Spacer()
                            Text(product.displayPrice)
                                .foregroundStyle(Theme.gold)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section("settings.about") {
            HStack {
                Text("settings.version")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Theme.textSecondary)
            }
            Text("settings.privacy_note")
                .font(Theme.bodyFont(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func showThanks() {
        thanksShown = true
        AnalyticsService.shared.log(event: "tip_tapped", params: [:])
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [QazaRecord.self, QazaCompletion.self, UserSettings.self],
                        inMemory: true)
}
