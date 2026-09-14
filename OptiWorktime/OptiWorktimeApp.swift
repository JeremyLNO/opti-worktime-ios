import SwiftUI

@main
struct OptiWorktimeApp: App {
    init() {
        let args = CommandLine.arguments
        L.current = L.systemDefault()
        if let i = args.firstIndex(of: "-demoLang"), i + 1 < args.count, let lang = AppLanguage(rawValue: args[i + 1]) {
            L.current = lang
        }
        if let i = args.firstIndex(of: "-fastDemo") {
            PomodoroEngine.testSeconds = (i + 1 < args.count ? Double(args[i + 1]) : nil) ?? 8
        }

        // Pont engine → Live Activity.
        PomodoroEngine.shared.onActivityEvent = {
            LiveActivityManager.shared.sync(PomodoroEngine.shared.activityState)
        }
        // Synchronisation iCloud (automatique, compte de l'appareil)
        CloudSync.shared.start()
        if args.contains("-startLiveActivity") {
            PomodoroEngine.shared.start()
        }
        OneSignalPush.start()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
