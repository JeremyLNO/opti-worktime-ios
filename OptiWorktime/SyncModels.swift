import Foundation

/// Total quotidien (identique côté Mac).
struct DayStat: Codable, Equatable {
    var focusSeconds: Int
    var sessions: Int
}

/// Instantané synchronisé via iCloud — MÊME format que le Mac (`~/opti-worktime`).
struct SyncSnapshot: Codable {
    var updatedAt: Date
    var deviceID: String
    var presetID: String
    var focusMin: Int
    var shortMin: Int
    var longMin: Int
    var cyclesBeforeLong: Int
    var plants: [PlantRecord]
    var days: [String: DayStat]
    var phase: String
    var running: Bool
    var end: Date
    var remaining: Double
    var phaseDuration: Double
    var completedInSet: Int
}
