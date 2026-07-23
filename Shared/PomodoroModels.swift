import SwiftUI

/// Les trois phases d'un cycle Pomodoro.
enum Phase: String, Codable, CaseIterable, Identifiable {
    case focus, shortBreak, longBreak
    var id: String { rawValue }
    var isBreak: Bool { self != .focus }

    var title: String {
        switch self {
        case .focus: L.t("Focus", "Concentration")
        case .shortBreak: L.t("Short break", "Petite pause")
        case .longBreak: L.t("Long break", "Longue pause")
        }
    }

    var symbol: String {
        switch self {
        case .focus: "leaf.fill"
        case .shortBreak: "cup.and.saucer.fill"
        case .longBreak: "moon.stars.fill"
        }
    }

    var color: Color { Palette.color(for: self) }
}

/// Un préréglage de durées (minutes) + nombre de focus avant la longue pause.
struct PomodoroPreset: Identifiable, Equatable, Codable {
    var id: String
    var nameEN: String
    var nameFR: String
    var focus: Int
    var short: Int
    var long: Int
    var cyclesBeforeLong: Int

    var localizedName: String { L.t(nameEN, nameFR) }
    var summary: String { "\(focus) · \(short) · \(long)" }
}

extension PomodoroPreset {
    static let classic  = PomodoroPreset(id: "classic",  nameEN: "Classic",   nameFR: "Classique",     focus: 25, short: 5,  long: 20, cyclesBeforeLong: 4)
    static let deepWork = PomodoroPreset(id: "deep",     nameEN: "Deep Work", nameFR: "Concentration", focus: 50, short: 10, long: 30, cyclesBeforeLong: 4)
    static let sprint   = PomodoroPreset(id: "sprint",   nameEN: "Sprint",    nameFR: "Sprint",        focus: 15, short: 3,  long: 15, cyclesBeforeLong: 4)
    static let all: [PomodoroPreset] = [.classic, .deepWork, .sprint]
}

/// Espèces récoltées dans le jardin (variété visuelle déterministe).
enum PlantSpecies: Int, CaseIterable, Codable {
    case sprout, tulip, sunflower, lavender, cactus, clover

    var bloomColor: Color {
        switch self {
        case .sprout:    Color(red: 0.45, green: 0.78, blue: 0.40)
        case .tulip:     Color(red: 0.93, green: 0.39, blue: 0.55)
        case .sunflower: Color(red: 0.98, green: 0.78, blue: 0.22)
        case .lavender:  Color(red: 0.66, green: 0.50, blue: 0.90)
        case .cactus:    Color(red: 0.36, green: 0.70, blue: 0.46)
        case .clover:    Color(red: 0.50, green: 0.80, blue: 0.45)
        }
    }
    var petals: Int {
        switch self {
        case .sprout: 0; case .tulip: 3; case .sunflower: 12
        case .lavender: 5; case .cactus: 0; case .clover: 4
        }
    }
    static func forIndex(_ i: Int) -> PlantSpecies {
        let c = allCases.count
        return allCases[((i % c) + c) % c]
    }
}

/// Une plante récoltée.
struct PlantRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var species: Int
    var focusMinutes: Int
    var plant: PlantSpecies { PlantSpecies(rawValue: species) ?? .sprout }
}
