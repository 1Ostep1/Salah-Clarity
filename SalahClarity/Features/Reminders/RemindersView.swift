//
//  RemindersView.swift
//  Salah Clarity
//

import SwiftUI

struct RemindersView: View {
    @State private var selectedCategory: Reminder.Category = .hadith
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        if selectedCategory == .hadith {
                            dailyCard
                                .transition(.asymmetric(
                                    insertion: .opacity
                                        .combined(with: .move(edge: .top))
                                        .combined(with: .scale(scale: 0.97)),
                                    removal: .opacity
                                        .combined(with: .move(edge: .top))
                                        .combined(with: .scale(scale: 0.97))
                                ))
                        }

                        categoryPicker

                        ForEach(HadithProvider.reminders(for: selectedCategory,
                                                         matching: searchText)) { reminder in
                            ReminderCard(reminder: reminder)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.35), value: selectedCategory)
                }
            }
            .navigationTitle("reminders.title")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
        }
    }

    // MARK: - Daily hadith highlight

    private var dailyCard: some View {
        let reminder = HadithProvider.dailyHadith()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                Text("reminders.daily_hadith")
                    .textCase(.uppercase)
                    .tracking(1.1)
                    .font(Theme.bodyFont(size: 12))
                Spacer()
            }
            .foregroundStyle(Theme.gold)

            Text(reminder.title)
                .font(Theme.titleFont())
                .foregroundStyle(.white)

            Text(reminder.body)
                .font(Theme.bodyFont())
                .foregroundStyle(.white.opacity(0.92))

            if let source = reminder.source {
                Text("— \(source)")
                    .font(Theme.bodyFont(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: 12) {
                Spacer()
                shareButton(for: reminder)
                copyButton(for: reminder)
            }
            .padding(.top, 4)
        }
        .cardStyle()
    }

    private var categoryPicker: some View {
        // Horizontally scrollable chips — avoids the segmented control's
        // fixed-width truncation when category titles are long or localized.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Reminder.Category.allCases, id: \.self) { cat in
                    CategoryChip(
                        title: cat.localizedTitle,
                        systemImage: cat.symbolName,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func shareButton(for reminder: Reminder) -> some View {
        ShareLink(item: shareText(for: reminder)) {
            Label("reminders.share", systemImage: "square.and.arrow.up")
                .font(Theme.bodyFont(size: 14))
                .foregroundStyle(Theme.gold)
        }
    }

    private func copyButton(for reminder: Reminder) -> some View {
        Button {
            UIPasteboard.general.string = shareText(for: reminder)
            AnalyticsService.shared.log(event: "reminder_copied", params: ["id": reminder.id])
        } label: {
            Label("reminders.copy", systemImage: "doc.on.doc")
                .font(Theme.bodyFont(size: 14))
                .foregroundStyle(Theme.gold)
        }
    }

    private func shareText(for reminder: Reminder) -> String {
        var text = "\(reminder.title)\n\n\(reminder.body)"
        if let src = reminder.source { text += "\n— \(src)" }
        return text
    }
}

// MARK: - Card

private struct ReminderCard: View {
    let reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: reminder.category.symbolName)
                    .foregroundStyle(Theme.gold)
                Text(reminder.title)
                    .font(Theme.titleFont(size: 17))
                    .foregroundStyle(.white)
                Spacer()
            }
            Text(reminder.body)
                .font(Theme.bodyFont())
                .foregroundStyle(.white.opacity(0.92))
            if let source = reminder.source {
                Text("— \(source)")
                    .font(Theme.bodyFont(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Category chip

private struct CategoryChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(Theme.bodyFont(size: 14))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Theme.gold.opacity(0.22)
                                          : Color.white.opacity(0.07))
            )
            .overlay(
                Capsule().stroke(isSelected ? Theme.gold
                                            : Color.white.opacity(0.15),
                                 lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Theme.gold : .white.opacity(0.85))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RemindersView()
}
