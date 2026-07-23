import ActivityKit
import WidgetKit
import SwiftUI

private func data(_ ctx: ActivityViewContext<PomodoroAttributes>) -> PomoLiveData {
    let s = ctx.state
    return PomoLiveData(
        phase: Phase(rawValue: s.phase) ?? .focus,
        start: s.start, end: s.end, running: s.running, remaining: s.remaining,
        cycle: s.cycle, cyclesTarget: s.cyclesTarget)
}

struct OptiWorktimeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroAttributes.self) { context in
            // Écran verrouillé / bannière.
            PomoLockView(d: data(context))
                .padding(16)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let d = data(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(d.phase.title).font(.caption).foregroundStyle(.white)
                    } icon: {
                        TomatoView(size: 20)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    liveTime(d)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(d.color)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        liveBar(d)
                        HStack {
                            cycleDots(d)
                            Spacer()
                            Text("\(L.t("Cycle", "Cycle")) \(min(d.cycle + 1, d.cyclesTarget)) \(L.t("of", "sur")) \(d.cyclesTarget)")
                                .font(.caption2).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
            } compactLeading: {
                TomatoView(size: 20)
            } compactTrailing: {
                liveTime(d)
                    .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(d.color)
                    .frame(maxWidth: 54)
            } minimal: {
                TomatoView(size: 18)
            }
            .keylineTint(d.color)
        }
    }
}
