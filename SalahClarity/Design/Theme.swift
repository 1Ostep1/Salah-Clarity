//
//  Theme.swift
//  Salah Clarity
//
//  Central colors, gradients, and typography.
//  Dark-first, mosque-inspired: deep green + warm gold accents.
//

import SwiftUI

enum Theme {

    // MARK: - Colors

    /// Deep, mosque-tile green. Primary brand color.
    static let green = Color(red: 0.04, green: 0.29, blue: 0.22)

    /// Softer accent green for highlights and progress bars.
    static let greenAccent = Color(red: 0.15, green: 0.55, blue: 0.42)

    /// Warm gold — use for active states, prayer-time highlights, crescent icon.
    static let gold = Color(red: 0.84, green: 0.69, blue: 0.34)

    /// Muted gold for secondary elements.
    static let goldMuted = Color(red: 0.62, green: 0.52, blue: 0.28)

    /// Background — near-black with a hint of green.
    static let background = Color(red: 0.04, green: 0.06, blue: 0.05)

    /// Elevated surface (cards).
    static let surface = Color(red: 0.08, green: 0.11, blue: 0.09)

    /// Secondary text.
    static let textSecondary = Color(white: 0.65)

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [background, Color(red: 0.06, green: 0.12, blue: 0.10)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let goldGradient = LinearGradient(
        colors: [gold, goldMuted],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Typography

    /// Use for the main prayer-time numbers and hero labels.
    static func displayFont(size: CGFloat = 44) -> Font {
        .system(size: size, weight: .light, design: .serif)
    }

    /// Use for section titles.
    static func titleFont(size: CGFloat = 22) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    /// Body copy.
    static func bodyFont(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    // MARK: - Shapes

    static let cardCornerRadius: CGFloat = 18
}

// Convenience modifier for cards.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(0.15), lineWidth: 0.75)
            )
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
