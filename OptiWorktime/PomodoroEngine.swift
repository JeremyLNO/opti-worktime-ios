import SwiftUI

/// Machine à états Pomodoro (iOS). Pilote l'UI (observée), la Live Activity (`onActivityEvent`)
/// et la synchro iCloud (`CloudSync.publish`).
@Observable
@MainActor
final class PomodoroEngine {
    static let shared = PomodoroEngine()

    nonisolated(unsafe) static var testSeconds: Double?

    // État observable
    private(set) var phase: Phase = .focus
    private(set) var isRunning = false
    private(set) var remaining: TimeInterval = 25 * 60
    private(set) var phaseDuration: TimeInterval = 25 * 60
    private(set) var completedInSet = 0
    private(set) var totalCompletedFocus = 0
    private(set) var wilting = false

    // Réglages (durées) persistés
    var presetID: String { didSet { d.set(presetID, forKey: "presetID") } }
    private(set) var focusMin: Int
    private(set) var shortMin: Int
    private(set) var longMin: Int
    private(set) var cyclesBeforeLong: Int

    // Jardin + stats persistés
    private(set) var plants: [PlantRecord]
    private(set) var days: [String: DayStat]

    var onActivityEvent: (() -> Void)?

    private let d = UserDefaults.standard
    private var endDate: Date?
    private var timer: Timer?
    private var applyingRemote = false

    private init() {
        presetID = d.string(forKey: "presetID") ?? PomodoroPreset.classic.id
        focusMin = d.object(forKey: "focusMin") as? Int ?? 25
        shortMin = d.object(forKey: "shortMin") as? Int ?? 5
        longMin = d.object(forKey: "longMin") as? Int ?? 20
        cyclesBeforeLong = d.object(forKey: "cyclesBeforeLong") as? Int ?? 4
        plants = (d.data(forKey: "plants").flatMap { try? JSONDecoder().decode([PlantRecord].self, from: $0) }) ?? []
        days = (d.data(forKey: "days").flatMap { try? JSONDecoder().decode([String: DayStat].self, from: $0) }) ?? [:]
        phaseDuration = phaseSeconds(.focus)
        remaining = phaseDuration
    }

    // MARK: Réglages / durées

    var gardenCount: Int { plants.count }
    var cyclesTarget: Int { max(1, cyclesBeforeLong) }
    var preset: PomodoroPreset { PomodoroPreset.all.first { $0.id == presetID } ?? .classic }

    private func minutes(for phase: Phase) -> Int {
        switch phase { case .focus: focusMin; case .shortBreak: shortMin; case .longBreak: longMin }
    }
    private func phaseSeconds(_ phase: Phase) -> TimeInterval {
        if let t = Self.testSeconds { return t }
        return TimeInterval(minutes(for: phase) * 60)
    }

    func applyPreset(_ id: String) {
        guard let p = PomodoroPreset.all.first(where: { $0.id == id }) else { return }
        presetID = p.id; focusMin = p.focus; shortMin = p.short; longMin = p.long; cyclesBeforeLong = p.cyclesBeforeLong
        persistSettings()
        if !isRunning { phaseDuration = phaseSeconds(phase); remaining = phaseDuration }
        onActivityEvent?(); publish()
    }
    private func persistSettings() {
        d.set(focusMin, forKey: "focusMin"); d.set(shortMin, forKey: "shortMin")
        d.set(longMin, forKey: "longMin"); d.set(cyclesBeforeLong, forKey: "cyclesBeforeLong")
    }
    private func persistGarden() { d.set(try? JSONEncoder().encode(plants), forKey: "plants") }
    private func persistDays() { d.set(try? JSONEncoder().encode(days), forKey: "days") }

    // MARK: Dérivés

    var progress: Double { phaseDuration > 0 ? min(1, max(0, 1 - remaining / phaseDuration)) : 0 }
    var displayTime: String {
        let s = max(0, Int(ceil(remaining)))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
    var activityEnd: Date { Date().addingTimeInterval(max(0, remaining)) }
    var activityStart: Date { activityEnd.addingTimeInterval(-phaseDuration) }
    var activityState: PomodoroAttributes.ContentState {
        PomodoroAttributes.ContentState(
            phase: phase.rawValue, start: activityStart, end: activityEnd,
            running: isRunning, remaining: remaining, cycle: completedInSet, cyclesTarget: cyclesTarget)
    }

    private func dayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    var todayFocusSeconds: Int { days[dayKey()]?.focusSeconds ?? 0 }
    var todaySessions: Int { days[dayKey()]?.sessions ?? 0 }

    // MARK: Contrôle

    func toggle() { isRunning ? pause() : start() }

    func start() {
        guard !isRunning else { return }
        if remaining <= 0 { remaining = phaseDuration }
        isRunning = true; wilting = false
        endDate = Date().addingTimeInterval(remaining)
        ensureTimer(); onActivityEvent?(); publish()
    }

    func pause() {
        guard isRunning else { return }
        if let endDate { remaining = max(0, endDate.timeIntervalSinceNow) }
        isRunning = false; endDate = nil
        onActivityEvent?(); publish()
    }

    func reset() {
        if phase == .focus && progress > 0.02 { triggerWilt() }
        isRunning = false; endDate = nil
        phaseDuration = phaseSeconds(phase); remaining = phaseDuration
        onActivityEvent?(); publish()
    }

    func skip() { complete(abandoned: true) }

    private func ensureTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common); timer = t
    }
    private func tick() {
        guard isRunning, let endDate else { return }
        remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 { remaining = 0; complete(abandoned: false) }
    }

    private func complete(abandoned: Bool) {
        let finished = phase
        if finished == .focus {
            if abandoned { triggerWilt() }
            else {
                let species = PlantSpecies.forIndex(plants.count).rawValue
                plants.append(PlantRecord(date: Date(), species: species, focusMinutes: Int((phaseDuration / 60).rounded())))
                persistGarden()
                var s = days[dayKey()] ?? DayStat(focusSeconds: 0, sessions: 0)
                s.focusSeconds += Int(phaseDuration); s.sessions += 1
                days[dayKey()] = s; persistDays()
                totalCompletedFocus += 1
            }
            completedInSet += 1
        }
        let next: Phase
        switch finished {
        case .focus: next = (completedInSet >= cyclesTarget) ? .longBreak : .shortBreak
        case .shortBreak: next = .focus
        case .longBreak: next = .focus; completedInSet = 0
        }
        phase = next; phaseDuration = phaseSeconds(next); remaining = phaseDuration; endDate = nil; isRunning = false
        start()
    }

    private func triggerWilt() {
        wilting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            MainActor.assumeIsolated { self?.wilting = false }
        }
    }

    // MARK: iCloud

    func snapshot(deviceID: String) -> SyncSnapshot {
        let now = Date()
        return SyncSnapshot(
            updatedAt: now, deviceID: deviceID, presetID: presetID,
            focusMin: focusMin, shortMin: shortMin, longMin: longMin, cyclesBeforeLong: cyclesBeforeLong,
            plants: plants, days: days, phase: phase.rawValue, running: isRunning,
            end: now.addingTimeInterval(max(0, remaining)), remaining: remaining,
            phaseDuration: phaseDuration, completedInSet: completedInSet)
    }

    func mergePlants(_ incoming: [PlantRecord]) {
        let known = Set(plants.map { $0.id })
        let fresh = incoming.filter { !known.contains($0.id) }
        guard !fresh.isEmpty else { return }
        plants.append(contentsOf: fresh); plants.sort { $0.date < $1.date }; persistGarden()
    }
    func mergeDays(_ incoming: [String: DayStat]) {
        var changed = false
        for (k, v) in incoming {
            let cur = days[k]
            let m = DayStat(focusSeconds: max(cur?.focusSeconds ?? 0, v.focusSeconds),
                            sessions: max(cur?.sessions ?? 0, v.sessions))
            if days[k] != m { days[k] = m; changed = true }
        }
        if changed { persistDays() }
    }
    func applySyncedSettings(presetID id: String, focus: Int, short: Int, long: Int, cycles: Int) {
        presetID = id; focusMin = focus; shortMin = short; longMin = long; cyclesBeforeLong = cycles
        persistSettings()
        if !isRunning { phaseDuration = phaseSeconds(phase); remaining = phaseDuration }
    }
    func applyRemoteSession(phaseRaw: String, running: Bool, end: Date,
                            remaining rem: Double, phaseDuration pd: Double, completedInSet cset: Int) {
        applyingRemote = true; defer { applyingRemote = false }
        phase = Phase(rawValue: phaseRaw) ?? .focus
        completedInSet = cset
        phaseDuration = pd > 0 ? pd : phaseSeconds(phase)
        if running {
            remaining = max(0, end.timeIntervalSinceNow); isRunning = true; endDate = end; ensureTimer()
        } else {
            remaining = max(0, rem); isRunning = false; endDate = nil
        }
        onActivityEvent?()
    }

    private func publish() {
        guard !applyingRemote else { return }
        CloudSync.shared.publish()
    }
}
