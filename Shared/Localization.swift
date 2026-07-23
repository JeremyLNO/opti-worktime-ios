import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, fr, de, es, pt
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .en: "English"; case .fr: "Français"; case .de: "Deutsch"; case .es: "Español"; case .pt: "Português"
        }
    }
    var flag: String {
        switch self {
        case .en: "🇬🇧"; case .fr: "🇫🇷"; case .de: "🇩🇪"; case .es: "🇪🇸"; case .pt: "🇵🇹"
        }
    }
}

/// Localisation EN/FR/DE/ES/PT (FR inline ; DE/ES/PT via table, repli EN).
enum L {
    nonisolated(unsafe) static var current: AppLanguage = systemDefault()

    static func systemDefault() -> AppLanguage {
        for pref in Locale.preferredLanguages {
            let code = pref.split(separator: "-").first.map { $0.lowercased() } ?? ""
            if let lang = AppLanguage(rawValue: code) { return lang }
        }
        return .en
    }

    static func t(_ en: String, _ fr: String) -> String {
        switch current {
        case .en: return en
        case .fr: return fr
        default: return table[en]?[current] ?? en
        }
    }

    static let table: [String: [AppLanguage: String]] = [
        "Focus": [.de: "Fokus", .es: "Concentración", .pt: "Concentração"],
        "Short break": [.de: "Kurze Pause", .es: "Pausa corta", .pt: "Pausa curta"],
        "Long break": [.de: "Lange Pause", .es: "Pausa larga", .pt: "Pausa longa"],
        "Start": [.de: "Start", .es: "Iniciar", .pt: "Iniciar"],
        "Pause": [.de: "Pause", .es: "Pausar", .pt: "Pausar"],
        "Skip": [.de: "Überspringen", .es: "Saltar", .pt: "Saltar"],
        "Reset": [.de: "Zurücksetzen", .es: "Reiniciar", .pt: "Reiniciar"],
        "Cycle": [.de: "Zyklus", .es: "Ciclo", .pt: "Ciclo"],
        "of": [.de: "von", .es: "de", .pt: "de"],
        "plants": [.de: "Pflanzen", .es: "plantas", .pt: "plantas"],
        "Today": [.de: "Heute", .es: "Hoy", .pt: "Hoje"],
        "Focus time": [.de: "Fokuszeit", .es: "Concentración", .pt: "Concentração"],
        "Sessions": [.de: "Sitzungen", .es: "Sesiones", .pt: "Sessões"],
        "ends": [.de: "endet", .es: "fin", .pt: "fim"],
        "left": [.de: "übrig", .es: "rest.", .pt: "rest."],
    ]
}
