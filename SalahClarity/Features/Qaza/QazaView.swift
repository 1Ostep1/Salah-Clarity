//
//  QazaView.swift
//  Salah Clarity
//
//  List screen: one row per prayer type (Fajr, Dhuhr, Asr, Maghrib, Isha)
//  showing remaining count, daily goal, and streak. Tap to open detail.
//

import SwiftUI
import SwiftData

struct QazaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QazaRecord.createdAt) private var records: [QazaRecord]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        overallCard
                        ForEach(Prayer.obligatory) { prayer in
                            NavigationLink(value: prayer) {
                                QazaRowCard(prayer: prayer, record: record(for: prayer))
                            }
                            .buttonStyle(.plain)
                        }

                        if records.isEmpty || records.allSatisfy({ $0.totalOwed == 0 }) {
                            emptyHint
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("qaza.title")
            .navigationDestination(for: Prayer.self) { prayer in
                QazaDetailView(prayer: prayer, record: record(for: prayer))
            }
        }
    }

    // MARK: - Overall progress

    private var overallCard: some View {
        let totalOwed = records.reduce(0) { $0 + $1.totalOwed }
        let totalDone = records.reduce(0) { $0 + $1.completed }
        let fraction = totalOwed > 0 ? Double(totalDone) / Double(totalOwed) : 0

        return VStack(alignment: .leading, spacing: 12) {
            Text("qaza.progress_title")
                .font(Theme.bodyFont(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.1)

            Text(String(format: NSLocalizedString("qaza.paid_back", comment: ""),
                        totalDone, totalOwed))
                .font(Theme.titleFont())
                .foregroundStyle(.white)

            ProgressView(value: fraction)
                .tint(Theme.gold)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var emptyHint: some View {
        Text("qaza.empty_hint")
            .font(Theme.bodyFont())
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    // MARK: - Record lookup / creation

    private func record(for prayer: Prayer) -> QazaRecord {
        if let existing = records.first(where: { $0.prayer == prayer }) {
            return existing
        }
        let new = QazaRecord(prayer: prayer, totalOwed: 0)
        modelContext.insert(new)
        try? modelContext.save()
        return new
    }
}

// MARK: - Row card

struct QazaRowCard: View {
    let prayer: Prayer
    let record: QazaRecord

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: prayer.symbolName)
                .font(.system(size: 24))
                .foregroundStyle(Theme.gold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(prayer.localizedName)
                    .font(Theme.titleFont(size: 18))
                    .foregroundStyle(.white)

                Text(String(format: NSLocalizedString("qaza.remaining", comment: ""),
                            record.remaining))
                    .font(Theme.bodyFont(size: 14))
                    .foregroundStyle(Theme.textSecondary)

                if record.currentStreak > 0 {
                    Label(String(format: NSLocalizedString("qaza.streak", comment: ""),
                                 record.currentStreak),
                          systemImage: "flame.fill")
                        .font(Theme.bodyFont(size: 12))
                        .foregroundStyle(Theme.gold)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("\(Int(record.progressFraction * 100))%")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.gold)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .cardStyle()
    }
}

#Preview {
    QazaView()
        .modelContainer(for: [QazaRecord.self, QazaCompletion.self, UserSettings.self],
                        inMemory: true)
}
