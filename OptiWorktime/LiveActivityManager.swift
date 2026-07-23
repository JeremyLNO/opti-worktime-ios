import ActivityKit
import Foundation

/// Démarre, met à jour et termine la Live Activity Pomodoro (Dynamic Island + écran verrouillé).
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<PomodoroAttributes>?
    var available: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// Démarre si besoin, sinon met à jour, avec l'état courant.
    func sync(_ state: PomodoroAttributes.ContentState) {
        guard available else { return }
        let content = ActivityContent(state: state, staleDate: state.running ? state.end : nil)

        if activity == nil { activity = Activity<PomodoroAttributes>.activities.first }

        if let activity {
            Task { await activity.update(content) }
        } else {
            do {
                activity = try Activity.request(
                    attributes: PomodoroAttributes(appName: "Opti Worktime"),
                    content: content, pushType: nil)
            } catch {
                print("[LiveActivity] start error: \(error)")
            }
        }
    }

    func end() {
        let acts = Activity<PomodoroAttributes>.activities
        activity = nil
        Task { for a in acts { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}
