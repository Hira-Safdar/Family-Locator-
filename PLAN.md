# Family Locator — Full Implementation Plan (0 to 100)

Goal: build from scratch (hand-writing every line) a consent-based real-time family GPS tracker app, modeled on "Phone Tracker – Family Locator". Android first, iOS later.

---

## 1. What we are building

Feature list (mapped from the reference app, minus the marketing fluff):

| Feature | Notes |
|---|---|
| Account system | Sign up / sign in with email + password. |
| Circles (groups) | A "family circle" = private group. Create / join via 6-char invite code. |
| Real-time location sharing | Each member's phone sends its GPS position periodically; other members see it live on a map. |
| Live member map | Google Maps with one marker per member, real-time updates, auto-fit camera to the circle. |
| Sharing control | Each member decides whether to share their location (consent is mandatory design). |
| SOS / panic alert | One-tap alert broadcasts to all circle members with your location + push notification. |
| Battery friendliness | Throttled updates, foreground service, adaptive intervals. |
| Find my phone | Ring your own device + see its last location. |
| Last-seen status | Shows for each member (fresh / stale). |
| Onboarding & privacy flow | Explains consent-based tracking before enabling anything. |

Out of scope for v1 (add later): geofencing/safe-zones, chat, phone-number tracking, history/playback.

**Security rule (non-negotiable):** only track members who explicitly accepted sharing. No "track by phone number" — that is fake in the market anyway and violates Play Store policy.

---

## 2. Tech stack (decided)

- **Frontend:** Flutter (Dart). Android first; same codebase later builds iOS on a Mac.
- **Backend:** Firebase (recommended choice).
  - Firebase Auth — accounts.
  - Cloud Firestore — users, circles, memberships, SOS alerts.
  - Realtime Database — high-frequency location ticks (cheaper + faster than Firestore for this).
  - Firebase Cloud Messaging (FCM) — push notifications (SOS, alerts).
  - Firebase Analytics + Crashlytics — production telemetry.
- **Maps:** google_maps_flutter + Google Maps SDK (Android).
- **Core packages:**
  - `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`, `firebase_messaging`
  - `google_maps_flutter`, `geolocator`
  - `flutter_foreground_task` (Android foreground service for background updates)
  - `flutter_riverpod` (state management)
  - `go_router` (navigation), `intl` (dates)
  - `fluttertoast` or `another_flutter_snackbar`-style helpers for feedback

**Why two data stores (Firestore + RTDB)?** Firestore is the structured source of truth (profiles, circles, memberships, invites, alerts). Locations change many times per minute, which would burn Firestore write costs and hit its per-document write rate limits — RTDB is purpose-built for that. Streams from both power the live map.

---

## 3. High-level architecture

```
┌─────────────────────────┐
│   Flutter app (Android) │
│                         │
│  UI layer (screens,     │
│  widgets)               │
│        │                │
│  State layer (Riverpod  │
│  providers/controllers) │
│        │                │
│  Repository layer       │
│  (your only touchpoint  │
│   to Firebase)          │
│        │                │
│  Firebase SDKs          │
└────────┬────────────────┘
         │
   ┌──────┴─────────────────────────────────────┐
   │            Firebase project                │
   │  Auth ─ users/circles/members/SOS (Firestore)│
   │  RTDB ─ circle locations subtree            │
   │  FCM  ─ push to circle members              │
   └────────────────────────────────────────────┘
```

Rules of thumb you keep forever:
- UI code never talks to Firebase directly — always through repositories. That keeps your screens testable and swapable.
- Every model class is immutable; repositories return data, never Firebase `DocumentSnapshot` objects.
- All background work goes through a foreground service, never an invisible background task (Play Store + battery rules).

---

## 4. Firebase data model

### Firestore collections

```
users/{uid}
  email, displayName, photoUrl, createdAt
  fcmToken                    (latest device token for notifications)
  sharingEnabled              (global master consent toggle)

circles/{circleId}
  name                        (e.g. "My Family")
  ownerUid
  inviteCode                  (6-char, e.g. "7-KWX2Q")
  createdAt

circles/{circleId}/members/{uid}
  role: "owner" | "member"
  nickname
  sharingEnabled              (per-circle consent)
  joinedAt
  color                       (marker color, assigned)

circles/{circleId}/sos/{alertId}
  fromUid, fromName
  lat, lng, message, createdAt
  status: "active" | "resolved"

invites/{code}
  circleId, createdAt          (join-by-code lookup; delete after use)
```

### Realtime Database tree

```
circles/{circleId}/locations/{uid}
  lat, lng, accuracy, battery
  ts                          (server epoch ms of this sample)
```

Membership "inverse" query (find my circles) is done client-side by querying `circles/{id}/members/{uid}` for the current `uid`, then loading each circle doc — standard pattern, no extra collection needed.

### Firestore security rules (hand-write these early)

You must write rules by hand in the Firebase console. Rule of thumb per collection:
- `users`: only self can read/write own profile.
- `circles`: readable/writable only by members (owner creates).
- `members/{uid}`: the member themselves, plus any member of the same circle.
- `sos`: members of the circle.
- `invites`: any signed-in user (that's the point of an invite code) — but encrypt/regenerate codes.
- RTDB locations: only members of that circle.

Even in the Firebase Emulator you practice rules; the rules file lives in the repo as `firestore.rules` and `database.rules`.

---

## 5. Project folder structure (what you will hand-create)

```
family_locator/
├── android/                  (generated; you edit manifest/gradle only)
├── firestore.rules
├── database.rules
├── pubspec.yaml
└── lib/
    ├── main.dart                      # entry: init Firebase, run app
    ├── app.dart                       # MaterialApp.router, theme, routes
    ├── core/
    │   ├── config/app_config.dart     # consts: update intervals, invite code chars
    │   ├── router/app_router.dart     # go_router table + auth redirect logic
    │   ├── theme/theme.dart           # colors, text styles
    │   ├── errors/failure.dart        # Failures (FirebaseError, NetworkError...)
    │   └── utils/geo.dart             # distance calc, marker color helpers
    ├── data/
    │   ├── models/
    │   │   ├── user_profile.dart      # immutable UserProfile
    │   │   ├── circle.dart            # Circle + inviteCode + owner
    │   │   ├── circle_member.dart     # role, nickname, sharingEnabled, color
    │   │   ├── location_point.dart    # lat,lng,accuracy,battery,ts, staleness
    │   │   └── sos_alert.dart
    │   ├── repositories/
    │   │   ├── auth_repository.dart   # signUp/signIn/signOut/stream
    │   │   ├── user_repository.dart   # profile CRUD + fcmToken update
    │   │   ├── circle_repository.dart # create/join/leave, members stream
    │   │   ├── location_repository.dart# write ticks to RTDB + config
    │   │   ├── sos_repository.dart    # send alert, listen to active alerts
    │   │   └── notification_repository.dart # token mgmt + FCM display
    │   └── providers.dart             # all Riverpod provider definitions
    ├── features/
    │   ├── onboarding/                # privacy consent explainer + start
    │   ├── auth/                      # login_screen, register_screen
    │   ├── shell/                     # home_shell with bottom nav
    │   ├── map/                       # map_screen, members_layer, member_sheet
    │   ├── circles/                   # create_circle, join_circle,
    │   │                              # circle_list, circle_detail
    │   ├── sos/                       # sos_button, sos_active_banner
    │   └── settings/                  # profile, sharing_toggle, about
    └── widgets/                       # shared: primary_button, text_field,
                                        # avatar_dot, loading_overlay, empty_state
```

Why "features" + "core" + "data": you can grow this to 50 screens without tangled imports. Every screen lives in one feature folder with only its own widgets.

---

## 6. Android setup you encode by hand

`android/app/src/main/AndroidManifest.xml` permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

Plus: `android.permission.ACCESS_BACKGROUND_LOCATION` must be requested separately (second prompt), and the app needs a foreground service declared. Note for later: Play Store requires a "Background Location" section in the Play Console + on-screen consent disclosure for this permission.

Add the Maps API key to `AndroidManifest.xml` (from Google Cloud Console — enable "Maps SDK for Android").

`android/app/build.gradle`: set `minSdk = 23`, and declare the foreground service type for location.

---

## 7. The roadmap — 12 phases

Estimated effort is for a learner hand-writing each line, ~2–4 focused hours/day.

### Phase 0 — Environment (1–2 days)
- Install Flutter SDK + Android Studio + an emulator (or a physical Android phone with USB debugging).
- `flutter create --org com.yourname --project-name family_locator family_locator`
- Run the counter app on the emulator. If `flutter run` works, you're ready.
- **Learn:** Flutter widget basics — `StatelessWidget`, `StatefulWidget`, `setState`, `MaterialApp`, basic layouts.

### Phase 1 — Map skeleton (2–3 days)
- Create an empty Firebase project (console.firebase.google.com). Add an Android app, download `google-services.json`, put it in `android/app/`.
- Add `google_maps_flutter` + `geolocator` to `pubspec.yaml`.
- Screen shows a Google Map centered on a hardcoded point, with one marker.
- Add a "locate me" button that uses `geolocator` to fetch the device position and re-centers the camera.
- Request runtime permission (fine location) with a clean explanation dialog.
- **Learn:** `Future`/`async`, permission request flows, plugin `Platform channels`, Google Cloud API keys.
- **Done when:** map loads, "locate me" snaps the camera to your real GPS position.

### Phase 2 — Firebase Auth + profile (3–4 days)
- Add `firebase_auth`, `cloud_firestore`, `firebase_core`.
- Write by hand: `AuthRepository` (signUp, signIn, signOut, authStateChanges stream).
- Screens: Register (email + password + display name), Login, loading-state handling, error mapping to user-friendly messages.
- On first sign-in, create the `users/{uid}` profile doc; update on subsequent logins.
- Write `user_repository.dart`, wire it with Riverpod (`authStateProvider` etc.).
- Write your first `firestore.rules` (self-only access) and test flows.
- **Learn:** streams, Riverpod `StreamProvider`/`AsyncNotifier`, Firestore security rules syntax.
- **Done when:** you can create an account, log out, log back in, and your profile persists.

### Phase 3 — Circles (4–5 days)
- `CircleRepository.createCircle(name)` writes the circle doc + owner membership + generates a random 6-char invite code (write the generator by hand with a `Random` and an alphabet constant).
- `CircleRepository.joinCircle(code)` → look up invite, add membership, delete invite.
- Screens: "No circles yet" empty state, Create Circle form, Join Circle by code, Circle list, Circle detail with member list.
- Show owner vs member roles in the member list.
- Hand-write Firestore rules for circles/members (members only).
- **Learn:** Firestore transactions (creating + joining atomically), multi-path writes, data model mapping, `StreamBuilder`-style reactive lists.
- **Done when:** two emulator/phone installs can create a circle and the second joins it via the code.

### Phase 4 — Real-time location sharing (4–5 days)
- Add `firebase_database`. `LocationRepository`:
  - `startSharing()` — begin a periodic loop (e.g. every 30 s while app is foreground) that fetches `geolocator` position and writes `circles/{circleId}/locations/{uid}`.
  - `listenToCircleLocations(circleId)` — stream of all member locations with staleness computed (older than 5 min = stale).
- Circle detail shows each member with a live "last seen X ago" and sharing on/off toggle (toggling `sharingEnabled` stops/starts the loop).
- **Learn:** RTDB data shape, streams, canceling subscriptions (`cancel` in a `StatefulWidget.dispose` or Riverpod `ref.onDispose`), doze-mode awareness.
- **Done when:** Device A's marker timestamp updates on Device B's screen within seconds, and toggling sharing off stops updates.

### Phase 5 — Live member map (4–5 days)
- `map_screen.dart`: render the selected circle, one marker per active member with their color.
- Update markers from the location stream without rebuilding the whole map (use `GoogleMapController` / `Set<Marker>` diff).
- "Fit to circle" button computes a bounds box from all locations and animates the camera.
- Tap a marker → bottom sheet: nickname, last-seen, accuracy, battery, and (for you) sharing toggle.
- Fresh markers filled, stale markers greyed on the map + "offline" state.
- **Learn:** `MarkersNotifier` in Riverpod, rendering performance, `CameraUpdate.newLatLngBounds`, sheet navigation.
- **Done when:** two devices show each other moving in real time on the maps.

### Phase 6 — SOS + push notifications (3–4 days)
- Add `firebase_messaging`. `NotificationRepository` registers the device token and stores it in `users/{uid}.fcmToken`.
- SOS flow: button on the map screen → confirm → write `circles/{id}/sos/{alertId}` (active) → send FCM to all circle members' tokens via Cloud Functions (`onCall` function in `functions/`, hand-written in `functions/index.js`).
- Members get a notification; tapping it opens the map centered on the alert location with a pulsing banner "⚠️ SOS from Name".
- Owner-only "Mark safe" resolves the alert.
- **Learn:** FCM token lifecycle, Cloud Functions `onCall`, notification channels (`NotificationChannel`), foreground/background notification handling divergences.
- **Done when:** a real push arrives on Device B when Device A hits SOS, and tap deep-links to the alert.

### Phase 7 — Battery & reliability engineering (3–4 days)
Cross-cutting pass — implement AppConfig tunables:
- Adaptive update interval: 15 s when circle is being watched, 60 s otherwise, 0 when sharing paused.
- `flutter_foreground_task`: a foreground service with an ongoing notification ("Family Locator is sharing your location") — required on modern Android for continuous location.
- Batch/limit writes; skip writing when position moved < 50 m.
- Handle app kill/restart: re-init sharing from saved preferences.
- **Learn:** Android foreground services, `onTaskRemoved`, efficiency vs accuracy tradeoffs.
- **Done when:** battery drain measurable and acceptable over 4 hours with the service running, and updates survive app backgrounding.

### Phase 8 — Find my phone (2 days)
- Settings action "Ring my phone": sends FCM self-notification → the receiving app plays a looping ringtone toggled by a button.
- Second screen: "Device location" — shows your last location from `users/{uid}` recorded during sharing.
- **Learn:** Media playback with `audioplayers`/`just_audio`, FCM self-messaging, foreground service tricks.
- **Done when:** you can ring your own phone from another logged-in device.

### Phase 9 — Quality pass (3–4 days)
- Write hand-authored `firestore.rules` and `database.rules` with unit tests against the Emulator (`flutter test` + `firebase emulators:exec`).
- Unit tests: `inviteCode` generator, staleness logic, marker diffing, geo helpers.
- Widget tests: login screen validation, empty-state rendering.
- Add Firebase Analytics screen views + Crashlytics; verify they report.
- Error handling sweep: every repository call returns `Result`/throws typed failures; every screen has retry + offline cache (e.g. `shared_preferences` micro-cache of last known positions).
- **Learn:** testing discipline, service locator freezes, error-state UI design.
- **Done when:** `flutter analyze` is clean, tests pass, and simulated offline shows cached last locations with a "stale" banner.

### Phase 10 — App icon, splash, polish (2–3 days)
- Create icons with `flutter_launcher_icons`, splash with `flutter_native_splash`.
- Onboarding screens: value pitch → privacy consent → permissions (one-tap, sequential).
- Consistent empty/loading/error states across all screens; finalize colors and typography in `theme.dart`.

### Phase 11 — Release build & Play Store (2–3 days)
- `flutter build appbundle --release`; create your Play Console app; complete the **Data safety form** (you handle location data — be precise), set consent disclosure for background location.
- Write the privacy policy page (plain text, hosted on GitHub Pages or a free site).
- Internal test track → closed testing (12 testers for 14 days) → production review.
- **Learn:** signing keys (`key.properties`), AAB vs APK, Play policy for location apps.

### Phase 12 — Post-launch (ongoing)
- Crashlytics monitoring, Firebase Analytics funnels, user feedback → prioritize.
- Backlog: geofencing (safe zones + enter/exit alerts), SOS location sharing history, multi-circle support, iOS port (same codebase; pointers via the geolocator/maps packages), per-member notification settings, optional passcode.

---

## 8. Cross-cutting rules to keep writing by hand correctly

1. **State flow:** screen → provider (Riverpod `AsyncNotifier`) → repository → Firebase. Never call Firebase in a widget.
2. **Consent-first UI:** The app must start with an onboarding screen explaining exactly what is tracked, who sees it, and how to turn it off. Toggle sharing OFF is one tap, visible in circle detail, settings, and the map sheet.
3. **Every async path has 3 states:** loading / data / error — build shared widgets (`LoadingOverlay`, `EmptyState`, `ErrorRetry`) and reuse.
4. **Never log or store locations anywhere except Firebase collections documented here.** No analytics event should carry coordinates.
5. **Time is always server time** (`FieldValue.serverTimestamp()` / `ServerValue.TIMESTAMP`) for everything you display, so two phones never disagree on staleness.
6. **Write tests alongside features**, not after — the only way this codebase stays safe as it grows.

---

## 9. Learning resources to pair with each phase

- Flutter fundamentals: https://docs.flutter.dev/get-started, https://flutter.dev/learn
- Maps: https://pub.dev/packages/google_maps_flutter
- Geolocation: https://pub.dev/packages/geolocator
- Firebase for Flutter: https://firebase.google.com/docs/flutter/get-started
- Security rules: https://firebase.google.com/docs/firestore/security/get-started
- FCM: https://firebase.google.com/docs/cloud-messaging
- Foreground services on Android: https://developer.android.com/develop/background-work/services/fgservice
- Riverpod: https://riverpod.dev
- go_router: https://pub.dev/packages/go_router

Golden rule for "write each line by hand": read the docs for a package *before* adding it; type every file yourself; use `flutter analyze` and your own unit tests as the referee — not copy-paste from an existing app.