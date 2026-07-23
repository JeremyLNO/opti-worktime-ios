import ActivityKit
import Foundation

/// Contrat ActivityKit partagé entre l'app (qui démarre/met à jour/termine la Live Activity)
/// et l'extension widget (qui la rend sur l'écran verrouillé et dans la Dynamic Island).
struct PomodoroAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var phase: String        // Phase.rawValue
        var start: Date          // début de la phase courante
        var end: Date            // fin prévue
        var running: Bool
        var remaining: Double    // secondes restantes (affichage à l'arrêt)
        var cycle: Int           // focus terminés dans la série
        var cyclesTarget: Int
    }

    var appName: String          // statique : « Opti Worktime »
}
