# Opti Worktime — iPhone

Version iPhone du Pomodoro **Opti Worktime**, avec une vraie **Live Activity** dans la
**Dynamic Island** (présentations compacte, étendue et minimale) + écran verrouillé.

## Ce qu'elle fait

- Écran principal : phase, **plante qui pousse**, gros minuteur, **barre de progression à tomate
  rebondissante**, pastilles de cycle, contrôles (réinitialiser / lecture-pause / passer), et un
  pied de page (plantes du jardin · concentration du jour · sessions).
- Préréglages Classic 25/5/20 · Deep Work 50/10/30 · Sprint 15/3/15.
- **Live Activity / Dynamic Island** : la tomate + le temps restant (auto-décompté) apparaissent
  dans la Dynamic Island ; en l'étendant : tomate + phase + temps + barre + cycle.
- Multilingue EN/FR/DE/ES/PT.

## Architecture

Projet Xcode 2 cibles (app + extension widget), `project.pbxproj` écrit à la main (mêmes
conventions que Cycles/Fasting). Bundle `company.lno.optiworktime`
(+ `.OptiWorktimeWidget`). iOS 17, Swift 5.

- `Shared/` (compilé dans les 2 cibles) : `PomodoroModels`, `Palette`, `Localization`,
  `PomodoroAttributes` (ActivityKit), `GardenVisuals` (tomate + plante + barre),
  `LiveActivityViews` (écran verrouillé + helpers temps/barre auto-décomptés).
- `OptiWorktime/` (app) : `OptiWorktimeApp`, `PomodoroEngine`, `ContentView`,
  `LiveActivityManager`.
- `OptiWorktimeWidget/` (extension) : `OptiWorktimeWidget` (WidgetBundle), `OptiWorktimeLiveActivity`
  (`ActivityConfiguration` + `DynamicIsland`).

La Live Activity ne dépend pas de push : les vues utilisent `Text(timerInterval:)` /
`ProgressView(timerInterval:)` qui s'auto-actualisent ; l'app ne synchronise que sur les
évènements (start/pause/phase/reset).

## Construire & lancer (simulateur)

```bash
./build-run.sh                 # build + install + lance sur « iPhone 16 Pro »
# puis :
xcrun simctl launch booted company.lno.optiworktime -startLiveActivity
```

Arguments de démo : `-startLiveActivity` (démarre direct), `-fastDemo 8` (phases de 8 s),
`-demoLang fr`. Pour voir la Dynamic Island, mettre l'app en arrière-plan (la Live Activity
survit à la fermeture de l'app).

## Synchronisation iCloud

Réglages, jardin, stats et **minuteur en cours** se synchronisent automatiquement avec l'app Mac
(`~/opti-worktime`) via `NSUbiquitousKeyValueStore` — pas de connexion à faire, c'est le compte
iCloud de l'appareil. La session en cours est partagée via une **fin absolue** (les deux appareils
décomptent vers le même instant). Entitlement `com.apple.developer.ubiquity-kvstore-identifier`
(même valeur que le Mac → store partagé). La synchro réelle nécessite un build **signé avec ton
équipe** + le même compte iCloud sur les deux appareils ; sinon le statut indique « connecte-toi à
iCloud » et l'app fonctionne en local.

## À venir

Widget d'écran d'accueil, notifications, réglages avancés.

## Push notifications (OneSignal)

The `OneSignal-XCFramework` Swift Package (pinned to **5.5.1**, only the
`OneSignalFramework` product) is linked into the app target, the app declares
`aps-environment` (`production`, even in Debug — the real environment is picked by the
provisioning profile, and `development` in a TestFlight build yields a token APNs rejects
in silence), and Push is enabled on the App ID `company.lno.optiworktime`.

Everything is gated on one constant — `OneSignalPush.appID` in
`OptiWorktime/OneSignalPush.swift`. While it is empty the SDK is never
initialised: no registration, no network call, no permission prompt. Paste the App ID
from onesignal.com ▸ Settings ▸ Keys & IDs to switch push on.

OneSignal carries Crazy Bee Labs announcements and app-update notices only; anything
this app schedules for itself stays a local notification. A tap on a push can only open
an `apps.apple.com` or `crazybeelabs.com` link — the payload is untrusted input.

Still required server-side before any push is delivered: an APNs `.p8` key uploaded to
the OneSignal app (Settings ▸ Platforms ▸ Apple iOS).
