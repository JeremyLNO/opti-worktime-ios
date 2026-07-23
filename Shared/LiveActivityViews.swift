import SwiftUI

/// Données simples pour rendre la Live Activity (sans dépendance ActivityKit dans les vues).
struct PomoLiveData {
    let phase: Phase
    let start: Date
    let end: Date
    let running: Bool
    let remaining: Double
    let cycle: Int
    let cyclesTarget: Int
    var color: Color { phase.color }
}

func pomoFmt(_ s: Double) -> String {
    let t = max(0, Int(s.rounded()))
    return String(format: "%d:%02d", t / 60, t % 60)
}

/// Temps restant : auto-décompté quand ça tourne, statique sinon.
@ViewBuilder func liveTime(_ d: PomoLiveData) -> some View {
    if d.running, d.end > d.start {
        Text(timerInterval: d.start...d.end, countsDown: true).monospacedDigit().multilineTextAlignment(.trailing)
    } else {
        Text(pomoFmt(d.remaining)).monospacedDigit()
    }
}

/// Barre de progression : auto-remplie quand ça tourne, statique sinon.
@ViewBuilder func liveBar(_ d: PomoLiveData) -> some View {
    if d.running, d.end > d.start {
        ProgressView(timerInterval: d.start...d.end, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
            .tint(d.color)
    } else {
        let total = max(1, d.end.timeIntervalSince(d.start))
        ProgressView(value: max(0, min(1, 1 - d.remaining / total))).tint(d.color)
    }
}

@ViewBuilder func cycleDots(_ d: PomoLiveData, dim: Color = .white.opacity(0.25)) -> some View {
    HStack(spacing: 5) {
        ForEach(0..<max(1, d.cyclesTarget), id: \.self) { i in
            Circle().fill(i < d.cycle ? d.color : dim).frame(width: 5, height: 5)
        }
    }
}

/// Carte de l'écran verrouillé / bannière.
struct PomoLockView: View {
    let d: PomoLiveData
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(d.color.opacity(0.18)).frame(width: 54, height: 54)
                TomatoView(size: 36)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label { Text(d.phase.title).font(.headline) } icon: {
                        Image(systemName: d.phase.symbol).foregroundStyle(d.color)
                    }
                    Spacer()
                    liveTime(d).font(.system(.title3, design: .rounded).weight(.bold)).foregroundStyle(d.color)
                }
                liveBar(d)
                HStack {
                    cycleDots(d, dim: .secondary.opacity(0.3))
                    Spacer()
                    Text("\(L.t("Cycle", "Cycle")) \(min(d.cycle + 1, d.cyclesTarget)) \(L.t("of", "sur")) \(d.cyclesTarget)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }
}
