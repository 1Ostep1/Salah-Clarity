//
//  QazaDetailView.swift
//  Salah Clarity
//
//  Per-prayer detail: log completions, set total owed, set daily goal,
//  see 30-day heatmap of consistency.
//

import SwiftUI
import SwiftData

struct QazaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let prayer: Prayer
    @Bindable var record: QazaRecord

    @State private var showingTotalSheet = false
    @State private var totalInput: String = ""

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    actionCard
                    goalCard
                    heatmapCard
                }
                .padding()
            }
        }
        .navigationTitle(prayer.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTotalSheet) { totalEditorSheet }
    }

    // MARK: - Cards

    private var headerCard: some View {
        VStack(spacing: 8) {
            Image(systemName: prayer.symbolName)
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)

            Text(String(format: NSLocalizedString("qaza.paid_back", comment: ""),
                        record.completed, record.totalOwed))
                .font(Theme.displayFont(size: 32))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            ProgressView(value: record.progressFraction)
                .tint(Theme.gold)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.horizontal)

            HStack(spacing: 24) {
                statBlock(title: "qaza.remaining", value: "\(record.remaining)")
                statBlock(title: "qaza.streak", value: "\(record.currentStreak)")
            }
            .padding(.top, 8)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.gold)
            Text(title)
                .font(Theme.bodyFont(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.1)
        }
    }

    private var actionCard: some View {
        VStack(spacing: 12) {
            Button(action: logCompletion) {
                Label("qaza.mark_prayed", systemImage: "checkmark.circle.fill")
                    .font(Theme.bodyFont().weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.goldGradient)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
            .disabled(record.remaining == 0)
            .opacity(record.remaining == 0 ? 0.4 : 1)

            Button {
                totalInput = "\(record.totalOwed)"
                showingTotalSheet = true
            } label: {
                Label("qaza.set_total", systemImage: "square.and.pencil")
                    .font(Theme.bodyFont())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(Theme.gold)
                    .overlay(
                        Capsule().strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .cardStyle()
    }

    private var goalCard: some View {
        HStack {
            Text(String(format: NSLocalizedString("qaza.daily_goal", comment: ""),
                        record.dailyGoal))
                .font(Theme.bodyFont())
                .foregroundStyle(.white)
            Spacer()
            Stepper(value: $record.dailyGoal, in: 1...20) { EmptyView() }
                .labelsHidden()
        }
        .cardStyle()
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("qaza.progress_title")
                .font(Theme.bodyFont(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.1)
            HeatmapGrid(completions: record.completions, days: 30)
        }
        .cardStyle()
    }

    private var totalEditorSheet: some View {
        NavigationStack {
            Form {
                TextField("Total", text: $totalInput)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("qaza.set_total")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingTotalSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Int(totalInput), value >= 0 {
                            record.totalOwed = value
                            try? modelContext.save()
                        }
                        showingTotalSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func logCompletion() {
        let completion = QazaCompletion(date: .now, record: record)
        modelContext.insert(completion)
        record.completed += 1
        try? modelContext.save()
        AnalyticsService.shared.log(event: "qaza_logged",
                                    params: ["prayer": prayer.rawValue])
    }
}

// MARK: - Heatmap

private struct HeatmapGrid: View {
    let completions: [QazaCompletion]
    let days: Int

    var body: some View {
        let byDay = Dictionary(grouping: completions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        let today = Calendar.current.startOfDay(for: .now)
        let cells: [(Date, Int)] = (0..<days).reversed().compactMap { offset in
            guard let d = Calendar.current.date(byAdding: .day, value: -offset, to: today)
            else { return nil }
            return (d, byDay[d]?.count ?? 0)
        }

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10),
                         spacing: 4) {
            ForEach(cells, id: \.0) { _, count in
                RoundedRectangle(cornerRadius: 4)
                    .fill(color(forCount: count))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private func color(forCount count: Int) -> Color {
        switch count {
        case 0: return Theme.surface.opacity(0.4)
        case 1: return Theme.gold.opacity(0.45)
        case 2: return Theme.gold.opacity(0.75)
        default: return Theme.gold
        }
    }
}
