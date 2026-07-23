import Foundation

/// Synchronisation iCloud automatique (compte de l'appareil) via `NSUbiquitousKeyValueStore`.
/// Aucune connexion explicite : si l'utilisateur est sur iCloud, ça fusionne tout seul avec le Mac.
@MainActor
final class CloudSync {
    static let shared = CloudSync()

    private let store = NSUbiquitousKeyValueStore.default
    private let key = "opti.sync.v1"
    private let d = UserDefaults.standard
    let deviceID: String
    private var applying = false
    private var lastLocalUpdate = Date.distantPast

    var available: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private init() {
        if let id = d.string(forKey: "deviceID") { deviceID = id }
        else { let id = UUID().uuidString; d.set(id, forKey: "deviceID"); deviceID = id }
    }

    func start() {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.pull() } }
        store.synchronize()
        pull()
    }

    func publish() {
        guard !applying, available else { return }
        lastLocalUpdate = Date()
        let snap = PomodoroEngine.shared.snapshot(deviceID: deviceID)
        if let data = try? JSONEncoder().encode(snap) {
            store.set(data, forKey: key)
            store.synchronize()
        }
    }

    private func pull() {
        guard let data = store.data(forKey: key),
              let snap = try? JSONDecoder().decode(SyncSnapshot.self, from: data),
              snap.deviceID != deviceID else { return }
        applying = true
        defer { applying = false }
        let e = PomodoroEngine.shared
        e.mergePlants(snap.plants)
        e.mergeDays(snap.days)
        if snap.updatedAt > lastLocalUpdate {
            e.applySyncedSettings(presetID: snap.presetID, focus: snap.focusMin,
                                  short: snap.shortMin, long: snap.longMin, cycles: snap.cyclesBeforeLong)
            e.applyRemoteSession(phaseRaw: snap.phase, running: snap.running, end: snap.end,
                                 remaining: snap.remaining, phaseDuration: snap.phaseDuration,
                                 completedInSet: snap.completedInSet)
        }
    }
}
