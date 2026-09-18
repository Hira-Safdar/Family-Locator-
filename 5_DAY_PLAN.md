# Family Locator — 5-Day Build Plan (learn-every-line edition)

Demo target: a working consent-based family tracker on Android. Every feature has a "demo version" and an explicit "production upgrade" note — cut corners are listed, not hidden.

Color legend: `[BUILD]` = files you hand-write · `[LEARN]` = concepts you must understand first · `[CHECK]` = exit criteria

---

## Day 1 — Foundation (setup, project anatomy, Firebase, Auth)

**AM — Environment (2–3 hrs)**
- `[LEARN]` What these are: Flutter SDK, `flutter` CLI, pub.dev packages, Android Studio, emulator, `AndroidManifest.xml`, Gradle. What a "package" is vs a "plugin".
- `[BUILD]` `flutter create --project-name family_locator --org <your-org> .` in this folder.
- `[LEARN]` Anatomy of the generated project (see structure below): `lib/`, `android/`, `pubspec.yaml`, `analysis_options.yaml`, `build/` (ignore it).
- `[LEARN]` Your first file `main.dart` **line by line**: `import`, `void main()`, `runApp`, `MaterialApp`, `Widget` class, `build()`, `home:`, `const`, `=>`, `final`, the counter app's `StatefulWidget`.
- `[BUILD]` Run the counter app on the emulator/phone. Learn hot reload (`r`) vs hot restart (`R`).
- `[LEARN]` answer: "should I use `setState` or Riverpod?" — both exist; we use Riverpod from Day 2, so most screens are `StatelessWidget`.

**Noon — Firebase connect (2 hrs)**
- `[BUILD]` Create Firebase project in console; add Android app (`com.<your-org>.family_locator`); download `google-services.json` → `android/app/`.
- `[BUILD]` `flutter pub add firebase_core firebase_auth cloud_firestore flutter_riverpod go_router`
- `[BUILD]` Run `flutterfire configure` → generates `lib/firebase_options.dart`.
- `[LEARN]` Manual `Firebase.initializeApp(options: DefaultFirebaseOptions.android)` vs using `WidgetsFlutterBinding.ensureInitialized()` first — and why main() alone can't async init cleanly.

**PM — Auth flow (3–4 hrs)**
- `[BUILD]` `lib/core/` folders (drag nothing, open Android Studio only if you need to navigate) — see tree below.
- `[BUILD]` Files: `app_config.dart`, `app_colors.dart`, `app_strings.dart`, `failure.dart`, `app_theme.dart`, `app_router.dart`.
- `[BUILD]` Data: `models/user_model.dart`, `repositories/auth_repository.dart`, `services/firebase_auth_service.dart`.
- `[BUILD]` `providers/auth_provider.dart`; features `splash/`, `auth/login_screen.dart`, `auth/signup_screen.dart`, `shared_widgets/`.
- `[BUILD]` Wire `main.dart` → init Firebase → splash decides route by auth state.

**[CHECK] Clean signup → auto-login → home shell placeholder → logout on the emulator. `flutter analyze` = 0 issues.**

---

## Day 2 — Groups + data layer (create/join by invite code)

**AM — Models, rules, code generator (2 hrs)**
- `[BUILD]` `models/group_model.dart`. `[LEARN]` fromJson/toJson, why `factory Group.fromJson`.
- `[BUILD]` `core/utils/code_generator.dart` — 6-char invite code using `Random` + alphabet. `[LEARN]` why not `uuid`? (shorter, human-readable). Also `core/utils/permission_helper.dart`.
- `[BUILD]` `firestore.rules` — self-only users, members-only groups, owner-write for groups (see rules section below). `[LEARN]` how rules evaluate, `request.auth.uid`, `resource.data`.
- `[CHECK]` Test each rule in the Firebase **Emulator**, not just the console.

**Noon — Repositories (2 hrs)**
- `[BUILD]` `repositories/group_repository.dart`: `createGroup`, `joinGroup(code)`, `leaveGroup`, `membersStream(groupId)`, `myGroupsStream(uid)`.
- `[LEARN]` Firestore `add` vs `set` vs `update`; why join uses a `WriteBatch`/transaction (two docs change together).
- `[BUILD]` `services/firestore_service.dart` (thin wrapper you build so screens never touch Firestore directly).

**PM — Screens + wiring (3 hrs)**
- `[BUILD]` `features/group_setup/create_group_screen.dart`, `join_group_screen.dart`, + `widgets/`.
- `[BUILD]` `providers/group_provider.dart`, `providers/settings_provider.dart`.
- `[BUILD]` `features/shell/` bottom-nav shell (Map / Groups / Settings tabs as placeholders).
- `[BUILD]` `features/settings/settings_screen.dart` (logout lives here already).

**[CHECK] Second emulator/phone joins your group using the 6-char code. Member list shows both. `flutter analyze` clean.**

---

## Day 3 — Map + real-time location (the demo centerpiece)

**AM — Map display (2 hrs)**
- `[BUILD]` Enable "Maps SDK for Android" in Google Cloud → API key → `AndroidManifest.xml`.
- `[BUILD]` `flutter pub add google_maps_flutter geolocator`
- `[BUILD]` `features/home_map/home_map_screen.dart`: GoogleMap widget, `initialCameraPosition`, "locate me" button via `geolocator`.
- `[LEARN]` `[BUILD]` permission flow: request "while using" first with explanation; the *second* "always allow" prompt only comes later (Play Store compliance).

**Noon — Location write + stream (2–3 hrs)**
- `[BUILD]` `services/location_service.dart`: `Timer`-based periodic `getCurrentPosition` → write to `users/{uid}.lastKnownLocation` (+ battery + `isSharing`). Skip writes when moved < 50 m (coalescing).
- `[BUILD]` `repositories/location_repository.dart`, `providers/location_provider.dart`, `providers/member_locations_provider.dart`.
- `[LEARN]` `StreamProvider` vs `StateNotifierProvider`; `.watch()` vs `.read()`; when to build with AsyncValue states (`data/loading/error`).
- `[BUILD]` quick `location_history` collection (`{uid, lat, lng, ts}`), written every Nth tick.

**PM — Live member map (2–3 hrs)**
- `[BUILD]` `widgets/member_marker.dart` (avatar/colored dot marker), `member_bottom_sheet.dart`, `map_controls.dart`.
- `[BUILD]` Update markers from the stream (diff, don't rebuild whole map); "fit to group" bounds button; stale (grey) markers.
- `[CHECK]` Device B sees Device A move on the map in real time, with last-seen + battery in the bottom sheet. `flutter analyze` clean.

---

## Day 4 — Member detail, simple background tracking, SOS + push

**AM — Member detail (2 hrs)**
- `[BUILD]` `features/member_detail/member_detail_screen.dart` + `location_history_view.dart` (recent history list from `location_history`).
- `[LEARN]` `Timeago`/`intl` formatting, "offline/stale" logic, accuracy display. `[CHECK]` both directions (A watches B, B watches A).

**Noon — Simple background tracking (2–3 hrs)**
- `[BUILD]` `services/background_location_service.dart` + `flutter pub add flutter_foreground_task flutter_local_notifications`
- `[LEARN]` Foreground service (ongoing "sharing location" notification) vs true background geolocation (commercial plugin) vs doing nothing. We choose the foreground service for the demo.
- `[BUILD]` `onTaskRemoved` + app restart re-inits sharing. Keep the same write path as Day 3 (reuse!).

**PM — SOS + FCM (2–3 hrs)**
- `[BUILD]` `flutter pub add firebase_messaging` → token → `users/{uid}.fcmToken` on login.
- `[BUILD]` `repositories/alert_repository.dart`, `services/fcm_service.dart`: SOS writes `alerts/{alertId}` + sends push to every group member token (Cloud Function, hand-written in `functions/index.js`).
- `[BUILD]` `features/sos/sos_button_widget.dart`, `sos_alert_screen.dart` (tap notification → centers map on alert).
- `[CHECK]` Real push arrives on device B when A hits SOS; tap opens the alert. `flutter analyze` clean.

---

## Day 5 — Privacy, alerts history, polish, demo

**AM — Settings/privacy (2 hrs)**
- `[BUILD]` `features/settings/privacy_controls_screen.dart`: pause/resume sharing (`isSharing`), "Clear my history" (manual delete of `location_history`) — production note: this becomes a Firestore TTL policy later.
- `[BUILD]` `features/settings/alerts_screen.dart` (list of past alerts, resolved state). `[BUILD]` `members_screen.dart` (rename/remove member, owner-only).

**PM — Edge cases + polish (3 hrs)**
- `[BUILD]` No-internet / permission-denied / GPS-off handling (shared `ErrorView` + retry), loading/empty states sweep.
- `[BUILD]` `flutter analyze` clean + unit tests for `code_generator`, `distance_calculator`, staleness.
- `[CHECK]` End-to-end run on **two real devices**: signup both → create/join group → map tracking → SOS push → privacy toggle → logout. 10-min demo script written.

**Stretch (only if ahead):** geofence engine (enter/exit by manual center + radius slider — keep as "Day 6" if time allows, drop it without guilt).

### Drop list (when behind — in this order)
1. Location `history` view → show only latest position + "history coming in v2".
2. Background (foreground-service) tracking → demo runs foreground only.
3. SOS push via Cloud Function → demo it as a local notification + list alert.
4. Member rename/remove screen.

### Demo script skeleton (Day 5 PM)
1. Signup on phone A (10 s).
2. Create group, read code aloud (10 s).
3. Join on phone B (10 s).
4. Show both heads on the map live, walk A across the room (30 s). **Centerpiece.**
5. Pause A's sharing → A's marker greys + last-seen freezes (15 s). **Consent proof.**
6. SOS on A → push pops on B → opens alert (15 s).
7. Clear history, logout, done (15 s).
Explicitly name the "next phase roadmap" during the talk: geofencing, motion-based battery tracking, TTL auto-delete, location history playback.

---

## Folder structure (honest 3-layer — UI/providers → data → core)

```
lib/
├── main.dart                      # entry point: init Firebase + runApp
├── firebase_options.dart          # auto-generated, don't hand-write
│
├── core/                          # framework-agnostic helpers
│   ├── constants/
│   │   ├── app_config.dart        # timers, radii, thresholds
│   │   ├── app_colors.dart
│   │   └── app_strings.dart       # every user-visible string in one place
│   ├── theme/app_theme.dart       # ThemeData, colors, text styles
│   ├── router/app_router.dart     # go_router table
│   ├── errors/failure.dart        # typed failures (AuthFailure, FirestoreFailure...)
│   └── utils/
│       ├── code_generator.dart    # 6-char invite codes
│       ├── distance_calculator.dart# haversine
│       └── date_formatter.dart
│
├── data/                          # everything that touches Firebase
│   ├── models/                    # plain Dart classes, no Firebase types
│   │   ├── user_model.dart
│   │   └── group_model.dart
│   ├── repositories/              # the ONLY allowed Firebase access point
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── group_repository.dart
│   │   └── location_repository.dart
│   └── services/                  # low-level wrappers + platform code
│       ├── firebase_auth_service.dart
│       ├── firestore_service.dart
│       ├── fcm_service.dart
│       ├── location_service.dart
│       └── background_location_service.dart
│
├── providers/                     # Riverpod wiring (StateNotifier/Stream)
│   ├── auth_provider.dart
│   ├── group_provider.dart
│   ├── location_provider.dart     # own tracking on/off state
│   ├── member_locations_provider.dart
│   └── settings_provider.dart
│
├── features/                      # one folder per screen-area (feature-first)
│   ├── splash/splash_screen.dart
│   ├── auth/                      # login_screen, signup_screen
│   ├── shell/                     # bottom-nav shell (Map/Groups/Settings)
│   ├── group_setup/               # create_group_screen, join_group_screen
│   ├── home_map/                  # home_map_screen + widgets/ (member_marker,
│   │                              #   member_bottom_sheet, map_controls)
│   ├── member_detail/             # member_detail_screen, location_history_view
│   ├── sos/                       # sos_button_widget, sos_alert_screen
│   ├── settings/                  # settings_screen, privacy_controls_screen,
│   │                              #   alerts_screen, members_screen
│   └── shared_widgets/            # loading_indicator, custom_button, error_view
```

Why this exact shape (the two rules that keep it survivable):
1. **Data layer is a wall.** Screens and providers import `data/repositories` only. Swap Firebase for your own server later by rewriting `data/` alone — `core/`, `providers/`, `features/` never change.
2. **Feature-first for humans.** Every screen, its widget, and its provider logic about *that screen* live close together; you never hunt across 20 folders.

---

## Firestore rules skeleton (Day 2 — tighten with Emulator tests)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn()  { return request.auth != null; }
    function isOwner(uid)  { return request.auth.uid == uid; }

    match /users/{userId} {
      allow read, write: if isSignedIn() && isOwner(userId);
    }

    match /groups/{groupId} {
      allow read: if isSignedIn() && request.auth.uid in resource.data.memberIds;
      allow write: if isSignedIn() && resource.data.createdBy == request.auth.uid;
      // create first login: allow create if signed in
      allow create: if isSignedIn() && request.resource.data.createdBy == request.auth.uid;
    }
  }
}
```

---

## What each day teaches you (the "what is what" glossary grows here)

- **Day 1:** `import`, `main()`, `runApp`, `Widget`, `build()`, `const/final/var`, `=>`, named params `{required ..}`, `StatefulWidget` vs `StatelessWidget`, hot reload vs restart, pubspec, `flutter analyze`.
- **Day 2:** `factory Class.fromJson`, `set` vs `add` vs `update`, `WriteBatch`/transaction, Flame/security rules, `Stream`, `.watch()` vs `.read()`.
- **Day 3:** `Timer`, `async/await`, `StreamProvider`, `AsyncValue.data/loading/error`, marker diffing, permission request patterns.
- **Day 4:** foreground services, notification channels, FCM tokens, `onCall` Cloud Function basics.
- **Day 5:** cache/offline UX, unit tests, release review checklist, demo hygiene.

Each term gets explained in chat the moment we first type it — with the "why this, not the alternative" answer.