import SwiftUI
import UIKit

struct ContentView: View {
    @State private var engine = PomodoroEngine.shared
    @AppStorage("push.cbl.enabled") private var cblNews = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        let color = engine.phase.color
        ZStack {
            LinearGradient(colors: Palette.background(for: engine.phase), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: engine.phase)

            VStack(spacing: 0) {
                header(color)

                Spacer(minLength: 8)

                PlantView(growth: engine.phase == .focus ? engine.progress : 1.0,
                          species: PlantSpecies.forIndex(engine.gardenCount),
                          swaying: true, wilting: engine.wilting)
                    .frame(width: 150, height: 130)

                Text(engine.displayTime)
                    .font(.system(size: 68, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.top, 4)

                TomatoProgressBar(progress: engine.progress, color: color)
                    .padding(.horizontal, 36)
                    .padding(.top, 6)

                HStack(spacing: 7) {
                    ForEach(0..<engine.cyclesTarget, id: \.self) { i in
                        Circle().fill(i < engine.completedInSet ? color : Color.white.opacity(0.22))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 14)

                Spacer(minLength: 12)

                controls(color)

                Spacer(minLength: 16)

                footer

                iCloudStatus
                    .padding(.top, 8)

                newsOptIn
                    .padding(.top, 6)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Header

    private func header(_ color: Color) -> some View {
        HStack {
            Label { Text(engine.phase.title).font(.headline) } icon: {
                Image(systemName: engine.phase.symbol).foregroundStyle(color)
            }
            .foregroundStyle(.white)
            Spacer()
            Menu {
                ForEach(PomodoroPreset.all) { p in
                    Button {
                        engine.applyPreset(p.id)
                    } label: {
                        if engine.presetID == p.id { Label("\(p.localizedName) · \(p.summary)", systemImage: "checkmark") }
                        else { Text("\(p.localizedName) · \(p.summary)") }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(engine.preset.localizedName)
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.white.opacity(0.08), in: Capsule())
            }
        }
        .padding(.top, 8)
    }

    // MARK: Controls

    private func controls(_ color: Color) -> some View {
        HStack(spacing: 40) {
            circleButton("arrow.counterclockwise", 56, 20) { engine.reset() }
            Button { engine.toggle() } label: {
                ZStack {
                    Circle().fill(color).frame(width: 88, height: 88)
                        .shadow(color: color.opacity(0.55), radius: 14)
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .bold)).foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            circleButton("forward.fill", 56, 20) { engine.skip() }
        }
    }

    private func circleButton(_ name: String, _ size: CGFloat, _ font: CGFloat, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.12)).frame(width: size, height: size)
                Image(systemName: name).font(.system(size: font, weight: .bold)).foregroundStyle(.white.opacity(0.9))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 12) {
            statTile("leaf.fill", "\(engine.gardenCount)", L.t("plants", "plantes"), Palette.leaf)
            statTile("timer", hms(engine.todayFocusSeconds), L.t("Today", "Aujourd'hui"), Palette.ember)
            statTile("checkmark.circle.fill", "\(engine.todaySessions)", L.t("Sessions", "Sessions"), Palette.mint)
        }
    }

    // iCloud : une app ne peut pas « se connecter » à iCloud elle-même → on ouvre les Réglages.
    @ViewBuilder private var iCloudStatus: some View {
        if CloudSync.shared.available {
            Label(L.t("iCloud sync on", "Synchro iCloud activée"), systemImage: "icloud.fill")
                .font(.caption2).foregroundStyle(.white.opacity(0.45))
        } else {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "icloud.slash")
                    Text(L.t("iCloud off · Open Settings", "iCloud désactivé · Ouvrir Réglages"))
                    Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                }
                .font(.caption2).foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }

    // Nouvelles Crazy Bee Labs. La permission système n'est demandée qu'au moment où
    // l'utilisateur dit oui — jamais au lancement, où elle n'aurait aucun sens à ses yeux.
    private var newsOptIn: some View {
        Button {
            cblNews.toggle()
            if cblNews { OneSignalPush.promptForPermission() }
            OneSignalPush.setOptedIn(cblNews)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: cblNews ? "bell.fill" : "bell.slash")
                Text(L.t("Crazy Bee Labs news", "Actualités Crazy Bee Labs"))
                Text(cblNews ? L.t("on", "activées") : L.t("off", "désactivées"))
                    .foregroundStyle(.white.opacity(cblNews ? 0.75 : 0.35))
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.45))
        }
        .buttonStyle(.plain)
    }

    private func statTile(_ icon: String, _ value: String, _ label: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(tint)
            Text(value).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private func hms(_ s: Int) -> String {
        let h = s / 3600, m = (s % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
