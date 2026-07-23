import SwiftUI

/// Palette d'Opti Worktime (iOS) — accents par phase + verts du jardin.
enum Palette {
    static let ember = Color(red: 0.96, green: 0.50, blue: 0.27)
    static let mint  = Color(red: 0.18, green: 0.80, blue: 0.62)
    static let sky   = Color(red: 0.27, green: 0.72, blue: 0.95)
    static let leaf  = Color(red: 0.33, green: 0.74, blue: 0.38)
    static let soil  = Color(red: 0.42, green: 0.30, blue: 0.21)

    static func color(for phase: Phase) -> Color {
        switch phase {
        case .focus: ember
        case .shortBreak: mint
        case .longBreak: sky
        }
    }

    /// Fond dégradé de l'app, teinté par la phase.
    static func background(for phase: Phase) -> [Color] {
        switch phase {
        case .focus:      [Color(red: 0.16, green: 0.11, blue: 0.09), Color(red: 0.10, green: 0.13, blue: 0.10)]
        case .shortBreak: [Color(red: 0.07, green: 0.16, blue: 0.14), Color(red: 0.08, green: 0.13, blue: 0.12)]
        case .longBreak:  [Color(red: 0.08, green: 0.13, blue: 0.18), Color(red: 0.08, green: 0.11, blue: 0.15)]
        }
    }
}
