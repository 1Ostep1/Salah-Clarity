//
//  QiblaView.swift
//  Salah Clarity
//
//  Compass-style view: rotates an arrow to point toward Makkah based on
//  the device's magnetic heading + computed bearing.
//

import SwiftUI
import CoreLocation

struct QiblaView: View {
    @State private var locationManager = LocationManager.shared
    @State private var viewModel = QiblaViewModel()

    /// Relative angle (in degrees) the arrow should rotate to point at Qibla.
    private var arrowAngle: Double {
        let heading = locationManager.currentHeading?.trueHeading ?? 0
        return viewModel.bearing - heading
    }

    private var isCalibrationNeeded: Bool {
        guard let h = locationManager.currentHeading else { return false }
        return h.headingAccuracy < 0 || h.headingAccuracy > 25
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 28) {
                    if locationManager.authorizationStatus == .denied ||
                        locationManager.authorizationStatus == .restricted {
                        locationDenied
                    } else {
                        compassDial
                        infoCard
                        if isCalibrationNeeded { calibrationHint }
                    }
                }
                .padding()
            }
            .navigationTitle("qibla.title")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            locationManager.requestAuthorization()
            locationManager.startUpdates()
            locationManager.startHeadingUpdates()
            if let loc = locationManager.currentLocation {
                viewModel.update(from: loc)
            }
        }
        .onDisappear {
            locationManager.stopHeadingUpdates()
        }
        .onChange(of: locationManager.currentLocation) { _, newValue in
            if let loc = newValue { viewModel.update(from: loc) }
        }
    }

    // MARK: - Subviews

    private var compassDial: some View {
        ZStack {
            // Outer ring
            Circle()
                .strokeBorder(Theme.gold.opacity(0.3), lineWidth: 2)
                .frame(width: 280, height: 280)

            // Tick marks
            ForEach(0..<24) { i in
                Rectangle()
                    .fill(Theme.gold.opacity(i % 6 == 0 ? 0.9 : 0.3))
                    .frame(width: 2, height: i % 6 == 0 ? 18 : 10)
                    .offset(y: -135)
                    .rotationEffect(.degrees(Double(i) * 15))
            }

            // Cardinal letters
            VStack { Text("N"); Spacer() }
                .frame(height: 260)
                .foregroundStyle(Theme.gold)
                .font(.system(size: 16, weight: .bold, design: .rounded))

            // Qibla arrow
            VStack(spacing: 0) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold.opacity(0.5), radius: 12)

                Rectangle()
                    .fill(LinearGradient(colors: [Theme.gold, Theme.goldMuted.opacity(0)],
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(width: 4, height: 90)
            }
            .offset(y: -40)
            .rotationEffect(.degrees(arrowAngle))
            .animation(.easeInOut(duration: 0.2), value: arrowAngle)

            // Kaaba icon in the center
            Image(systemName: "building.columns.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.gold)
                .padding(14)
                .background(Theme.surface)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Theme.gold.opacity(0.4), lineWidth: 1))
        }
        .frame(width: 300, height: 300)
    }

    private var infoCard: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.0f°", viewModel.bearing))
                .font(Theme.displayFont(size: 38))
                .foregroundStyle(Theme.gold)
            Text(String(format: NSLocalizedString("qibla.distance", comment: ""),
                        formattedDistance(viewModel.distanceKm)))
                .font(Theme.bodyFont())
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var calibrationHint: some View {
        Label("qibla.calibrate", systemImage: "arrow.2.circlepath")
            .font(Theme.bodyFont(size: 14))
            .foregroundStyle(Theme.gold)
            .multilineTextAlignment(.center)
            .padding()
            .cardStyle()
    }

    private var locationDenied: some View {
        VStack(spacing: 14) {
            Image(systemName: "location.slash")
                .font(.system(size: 36))
                .foregroundStyle(Theme.gold)
            Text("qibla.location_needed")
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
        }
        .padding()
        .cardStyle()
    }

    private func formattedDistance(_ km: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        return nf.string(from: NSNumber(value: km)) ?? "\(Int(km))"
    }
}

#Preview {
    QiblaView()
}
