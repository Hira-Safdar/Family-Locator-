# Family Locator — Complete App Log

> Generated: 21 Oct 2026
> Purpose: app ki har screen, widget, button, tab, function, settings tile aur backend ka mukammal record.
> Platform: Android only (iOS support hata di gayi hai).

---

## 0. Project Identity

| Cheez | Value |
|---|---|
| App name | Family Locator |
| Package name | `familylocator` |
| Version | `1.0.0+1` |
| Dart SDK | `^3.12.2` |
| Firebase project | `family-locator-4551f` |
| Android applicationId | `com.mylocator.familylocator` |
| Entry file | `lib/main.dart` |
| Language | Flutter / Dart |
| State management | Riverpod 3.4.3 |
| Routing | go_router 17.4.0 |

---

## 1. Dependencies (`pubspec.yaml`)

### Runtime
- `flutter_riverpod` ^3.4.3 — state management
- `go_router` 17.4.0 — navigation
- `firebase_core` ^4.15.0 — Firebase init
- `firebase_auth` ^6.7.0 — authentication
- `cloud_firestore` ^6.10.0 — database
- `firebase_messaging` ^16.7.0 — push notifications
- `qr_flutter` ^4.1.0 — invite QR generate
- `mobile_scanner` ^7.4.2 — QR scan
- `geolocator` ^14.1.1 — location
- `google_maps_flutter` ^2.18.1 — map
- `permission_handler` 11.4.0 — permissions
- `share_plus` ^13.3.1 — share invite / app
- `url_launcher` ^6.3.3 — external links
- `shared_preferences` ^2.5.6 — local settings
- `image_picker` ^1.2.4 — profile photo
- `flutter_local_notifications` ^22.3.1 — local SOS + campaign notifications
- `flutter_background_service` ^5.1.0 — background location
- `battery_plus` ^7.1.2 — battery level
- `package_info_plus` ^10.2.2 — app version
- `google_mobile_ads` ^9.1.0 — AdMob banners

### Dev
- `flutter_test`
- `flutter_lints` ^6.0.0
- `flutter_native_splash` ^2.4.8

---

## 2. App Startup Flow (`lib/main.dart`)

`main()`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Firebase.initializeApp(options: DefaultFirebaseOptions.android)`
3. `initializeBackgroundService()` — background service + `location_sharing` channel configure
4. `MobileAds.instance.initialize()`
5. `SharedPreferences.getInstance()`
6. `NotificationService().init()` — `sos_alerts` + `campaigns` channels create
7. `notifications.requestPermission()` — Android 13+ notification permission
8. `runApp(ProviderScope(...))` with overrides:
   - `sharedPreferencesProvider`
   - `notificationServiceProvider`
9. `FamilyApp` → `MaterialApp.router`:
   - `title: AppStrings.appName`
   - `theme: AppTheme.light`
   - `darkTheme: AppTheme.dark`
   - `themeMode: settingsProvider.themeMode`
   - `routerConfig: routerProvider`

`FamilyApp` class:
- `build(context, ref)` — router + theme mode watch karta hai.

---

## 3. Navigation / Routes (`lib/core/router/app_router.dart`)

`routerProvider`:
- `authState` = `authStateProvider`
- `splashHold` = `minimumSplashProvider`
- Redirect:
  - jab tak auth loading ya splash hold loading ho → `null` (stay)
  - logged out + login/signup/forgot ke ilawa → `/login`
  - logged in + login/signup/forgot/`/` → `/home`
  - `/members` bina `groupId` → `/home`
- `errorBuilder` → `NotFoundScreen(location)`
- `initialLocation: '/'`

| Route | Screen | Parameters |
|---|---|---|
| `/` | `SplashScreen` | — |
| `/login` | `LoginScreen` | — |
| `/signup` | `SignupScreen` | — |
| `/forgot-password` | `ForgotPasswordScreen` | — |
| `/home` | `HomeShell` | — |
| `/choose-group` | `ChooseGroupScreen` | — |
| `/create-group` | `CreateGroupScreen` | `?category=` (default `Custom`) |
| `/join-group` | `JoinGroupScreen` | — |
| `/invite` | `InviteScreen` | `?code=`, `?name=` |
| `/view-profile` | `ViewProfileScreen` | — |
| `/privacy` | `PrivacyControlsScreen` | — |
| `/alerts` | `AlertsScreen` | — |
| `/alert-map` | `AlertMapScreen` | `?lat=`, `?lng=`, `?name=` |
| `/members` | `MembersScreen` | `?groupId=` (required) |
| `/change-password` | `ChangePasswordScreen` | — |
| `/change-email` | `ChangeEmailScreen` | — |

---

## 4. Bottom Navigation Tabs (`lib/features/shell/home_shell.dart`)

`HomeShell` — `ConsumerStatefulWidget`

- Body: `IndexedStack` with 3 children:
  1. `HomeScreen` — Map tab
  2. `GroupsScreen` — Groups tab
  3. `SettingsScreen` — Settings tab
- Bottom: `NavigationBar` with 3 `NavigationDestination`:
  - Map — `Icons.map_outlined` / `Icons.map`
  - Groups — `Icons.people_outline` / `Icons.people`
  - Settings — `Icons.settings_outlined` / `Icons.settings`
- `_index` state — selected tab.

Functions:
- `initState()` → `_registerPushToken()` + `_listenNotificationTaps()` + `_listenCampaigns()`
- `_registerPushToken()` → `MessagingService.register()` → `saveFcmToken(uid, token)`; `onTokenRefresh` subscribe
- `_listenNotificationTaps()` → `onMessageOpenedApp` subscribe + `getInitialMessage()` check
- `_listenCampaigns()` → `FirebaseMessaging.onMessage`; `type == "campaign"` + settings ON par `showCampaign()` + `campaignBannerProvider.show()`
- `_openNotification(message)` → `type == "sos"` par `latitude`/`longitude` se `/alert-map?lat=&lng=&name=` push (missing coords → `/alerts`); campaign tap par koi navigation nahi
- `dispose()` → token + tap + message subscriptions cancel
- `build()` → `Stack` (IndexedStack + top `CampaignBanner` overlay, teeno tabs ke upar) + NavigationBar

> Note: `IndexedStack` ki wajah se teeno screens zinda rehti hain, is liye Map screen ka SOS listener har tab par chalta rehta hai.

---

## 5. Shared Widgets (`lib/shared_widgets/`)

### `CustomButton`
- Props: `onPressed`, `label`, `isLoading`
- `build()` → `ElevatedButton`; loading par spinner

### `LoadingIndicator`
- Props: `onRetry`, `timeout` (default 10s)
- State: `_timedOut`
- `initState()` — timer start
- `dispose()` — timer cancel
- `build()` — spinner; timeout ke baad `OfflineView`

### `ErrorView`
- Props: `message`, `onRetry`
- `build()` — center text + optional `Retry` button

### `OfflineView`
- Props: `onRetry`, `title` (default "No internet connection"), `subtitle` (default "Check your connection and try again.")
- `build()` — wifi_off icon, title, subtitle, optional "Try Again" button

### `ProfileAvatar`
- Props: `name`, `photoUrl`, `radius` (default 20)
- `build()` — `CircleAvatar`; photo ho to image, warna name ka first letter
- `_image()` — `data:` URI ko base64 decode (`MemoryImage`), warna `NetworkImage`

### `BannerAdWidget`
- Props: `adUnitId` (required)
- State: `_bannerAd`, `_loaded`, `_started`
- `didChangeDependencies()` — ek dafa `_loadAd()`
- `_loadAd()` — adaptive banner size (`getLargeAnchoredAdaptiveBannerAdSizeWithOrientation`), load
- `dispose()` — ad dispose
- `build()` — load hone tak 50px placeholder, phir `AdWidget`

### `CampaignBanner`
- Props: `title`, `body`, `onDismiss`
- State: `_timer` (8 seconds)
- `initState()` / `didUpdateWidget()` — timer start/reset
- `dispose()` — timer cancel
- `build()` — top se slide-in (`TweenAnimationBuilder` + `FractionalTranslation`), `Material` card, campaign icon, title 16/w600, body 14, X button

---

## 6. Screens (Detail)

### 6.1 Splash — `lib/features/splash/splash_screen.dart`
- `SplashScreen` (Stateless)
- Background: `AppColors.primary` (green)
- Center column:
  - `Icons.family_restroom` (72, white)
  - App name text
  - `CircularProgressIndicator` (26x26, white)
- Minimum hold: `minimumSplashProvider` = 1.8 seconds
- Functions: `build()`

### 6.2 Login — `lib/features/auth/login_screen.dart`
- `LoginScreen` → `_LoginScreenState`
- AppBar: none (custom layout)
- Widgets:
  - Family icon (72)
  - `AppStrings.loginTitle` ("Welcome Back!")
  - Subtitle "Sign in to see your family on the map"
  - Email `TextField` (`Icons.email_outlined`)
  - Password `TextField` (`Icons.lock_outline`) + visibility toggle
- Buttons / actions:
  - "Forgot password?" → `/forgot-password`
  - "Sign In" `CustomButton` → `_submit()`
  - "Sign Up" `TextButton` → `/signup`
- Validation: email regex, password non-empty
- Functions:
  - `_validateEmail(email)`
  - `_submit()` → `authController.signIn` → `/home`
  - `dispose()`
  - `build()`

### 6.3 Signup — `lib/features/auth/signup_screen.dart`
- `SignupScreen` → `_SignupScreenState`
- AppBar: empty
- Widgets:
  - "Create your account"
  - Full Name field
  - Email field
  - Password field + visibility toggle
  - Confirm Password field + visibility toggle
  - `CheckboxListTile` — "I agree to the Terms of Service and Privacy Policy"
- Buttons:
  - "Sign Up" `CustomButton` → `_submit()`
  - "Sign In" `TextButton` → `/login`
- Validation: name non-empty, email regex, `PasswordValidator`, confirm match, terms accepted
- Functions: `_validateEmail`, `_validatePassword`, `_submit`, `dispose`, `build`

### 6.4 Forgot Password — `lib/features/auth/forgot_password_screen.dart`
- `ForgotPasswordScreen` → `_ForgotPasswordScreenState`
- States: `_sent` (form vs sent view)
- Form widgets:
  - `Icons.lock_reset` (72)
  - "Forgot password?"
  - Description
  - Email field
  - "Send reset link" `CustomButton`
  - "Sign In" `TextButton` → `/login`
- Sent view:
  - `Icons.mark_email_read_outlined` (green)
  - "Check your email"
  - Email mention
  - "Back to sign in" `CustomButton`
- Functions: `_validateEmail`, `_submit`, `dispose`, `build`, `_formView`, `_sentView`

### 6.5 Home Map — `lib/features/home_map/home_map_screen.dart`
- Class: `HomeScreen` → `_HomeScreenState`
- AppBar: none (floating top bar)
- Map:
  - `GoogleMap` initial fallback `LatLng(30.3753, 69.3451)` zoom 6
  - `myLocationEnabled: false`, `myLocationButtonEnabled: false`
  - `zoomControlsEnabled: false`, `mapToolbarEnabled: false`, `compassEnabled: true`
- Markers:
  - "me" — green marker
  - Members — orange; selected — red (higher zIndex)
- Floating widgets:
  - Top bar: `Icons.family_restroom` + "Live Tracking"
  - Error banner (red) — location/member load error
  - SOS banner (red) — `Icons.emergency` + text + "View" (others) + "Resolve"/"Cancel"
  - `LoadingIndicator` / `OfflineView` / "No group yet" card
  - Bottom card:
    - Default: `_groupBox` (group name, member count, next-group chevron, own last seen)
    - Selected self: `_youBox` (avatar, name, "You" badge, last seen, stale warning, accuracy, battery)
    - Selected member: `_memberBox` (avatar, name, owner badge, last seen, stale warning, distance, accuracy, battery, "MEMBER OF" group list)
  - FAB "My location" (mini) → `_centerOnMe()`
  - FAB "Send SOS" (red, mini) → `_confirmSos()` — sirf jab group me 1 se zyada member hon
- Dialogs:
  - "Send SOS?" confirm dialog → Cancel / Send SOS
  - "SOS failed" error dialog
- Functions:
  - `initState()` — location controller start (microtask)
  - `dispose()` — map controller dispose
  - `_nextGroup(groups)` — agla group select
  - `build()` — listeners + markers + overlays
  - `_centerOnMe()` — camera apni location par
  - `_confirmSos(group)` — confirm dialog
  - `_sendSos(group)` — current point → `sendSos()`; error handling
  - `_resolveSos(group)` — `resolveSos()`
  - `_focusOnSos(sos)` — camera SOS location par
  - `_notifySosIfNeeded(group, selfUid)` — local notification (dedup `_notifiedSos`, settings gate)
  - `_showSosError(message)`
  - `_sosBanner(group, selfUid)`
  - `_groupBox(groups, active, myPoint)`
  - `_memberBox(active, groups, uid, point, myPoint)`
  - `_youBox(active, groups, uid, point)`
  - `_ownerBadge()`
  - `_infoRow(icon,label,value,{valueColor})`
  - `_isStale(point)` — 5 min se purana
  - getter `_cardDecoration`

### 6.6 All Groups — `lib/features/group_setup/groups_screen.dart`
- Class: `GroupsScreen` → `_GroupsScreenState`
- AppBar: "All Groups"
- Top widgets:
  - `FilledButton.icon` — "Create Group" → `/choose-group`
  - `OutlinedButton.icon` — "Join a Group" → `/join-group`
  - `BannerAdWidget(AdUnits.groupsBanner)`
  - Search `TextField` — "Search by name or code" + clear
  - Category `ChoiceChip` row — "All" + Friends / School / Office / Travel / Custom
  - Sort `PopupMenuButton` — "Newest first", "Name (A-Z)", "Most members"
- List states:
  - empty → `_EmptyState` ("No groups yet")
  - no matches → `_NoMatches` ("No matching groups")
  - `_GroupCard`:
    - Initial avatar
    - Group name
    - "Owner" badge (owner ko)
    - Member count
    - Category chip
    - Invite code (tap → copy)
    - `PopupMenuButton`: "Edit name" (owner), "Share invite", "Show QR"
- Dialogs:
  - QR dialog — 200x200 QR, group name, invite code, Close
  - Rename dialog — group name field, Cancel / Save
- Functions:
  - `dispose()`
  - `_apply(groups)` — search + category filter + sort
  - `_refresh()` — invalidate + await
  - `build()`
  - `_categoryChip(label, selected, onTap)`
  - `_GroupCard._showRename(context, ref)`
  - `_GroupCard.build(context, ref)`
  - `_GroupCard._showQr(context)`
  - `_RenameGroupDialogState._save()`
  - helpers: `_ScrollableMessage.build`, `_EmptyState.build`, `_NoMatches.build`, `_RenameGroupDialogState.dispose/build`

### 6.7 Choose Group — `lib/features/group_setup/choose_group_screen.dart`
- `ChooseGroupScreen` → `_ChooseGroupScreenState`
- AppBar: "Choose Group"
- Heading: "What kind of group are you creating?"
- 5 `_CategoryCard`s (Friends, School, Office, Travel, Custom) with icon + hint + check state
- Bottom: "Continue" `ElevatedButton` (disabled until selection) → `/create-group?category=...`
- Functions: `_continue()`, `build()`, `_CategoryCard.build()`

### 6.8 Create Group — `lib/features/group_setup/create_group_screen.dart`
- `CreateGroupScreen` (category param) → `_CreateGroupScreenState`
- AppBar: "New Group"
- Widgets:
  - `Icons.group_add` (72)
  - "Create a group to start tracking each other"
  - Category chip + "Change" → `/choose-group`
  - Group name `TextField`
  - Duplicate error text
  - Suggestions label "Try one of these" + `ActionChip`s
- Button: "Create Group" `CustomButton` → `_submit()`
- Behavior: 500ms debounce duplicate check; `isNameTaken`; `suggestNames`
- Functions:
  - `dispose()`
  - `_onChanged(value)` — debounce
  - `_checkDuplicate()`
  - `_applySuggestion(suggestion)`
  - `_submit()` → `createGroup()` → `/invite?code=&name=`
  - `build()`

### 6.9 Join Group — `lib/features/group_setup/join_group_screen.dart`
- `JoinGroupScreen` → `_JoinGroupScreenState`
- AppBar: "Join Group"
- Widgets:
  - `Icons.group_add` (72)
  - "Ask a family member for their invite code"
  - Invite code `TextField` (max 6, uppercase) + QR scan suffix icon
- Buttons:
  - "Join Group" `CustomButton` → `_submit()`
  - "Scan QR Code" `OutlinedButton.icon` → `_scanQr()`
- `_ScanQrDialog`:
  - `MobileScanner`
  - Camera permission error view (Roman Urdu message) + Close
- Functions: `_scanQr()`, `dispose()`, `_submit()`, `build()`, `_ScanQrDialogState.build()`

### 6.10 Invite — `lib/features/group_setup/invite_screen.dart`
- `InviteScreen(code, name)` (Stateless)
- AppBar: "Invite Members"
- Widgets:
  - `Icons.check_circle_outline` (green)
  - "Group created!"
  - Group name
  - "Share this code or QR with the people you want to add."
  - 200x200 QR
  - Invite code chip (tap → copy)
- Buttons:
  - "Copy code" `OutlinedButton.icon`
  - "Share invite" `CustomButton`
  - "Done" `TextButton` → `/home`
- Functions: `build()`

### 6.11 Settings — `lib/features/settings/settings_screen.dart`
- Class: `SettingsScreen` → `_SettingsScreenState` (with `WidgetsBindingObserver`)
- AppBar: "Settings"
- Body: `ListView` with sections and tiles.

#### Profile header (top card)
- `ProfileAvatar(radius: 32)` — name + email + chevron
- Tap → `/view-profile`
- Function: `_profileHeader(context)`

#### Section "Manage Permissions"
1. **Location Permission**
   - Icon: `Icons.location_on_outlined`
   - Subtitle dynamic: "Always allowed" / "While using the app" / "Denied" / "Not allowed"
   - Trailing icon: `check_circle` / `block` / `warning_amber` (color success/error/warning)
   - Tap → `openAppSettings`
2. **Appearance**
   - Icon: `Icons.brightness_6_outlined`
   - Subtitle: `System default` / `Light` / `Dark`
   - Tap → `_pickThemeMode()` → `SimpleDialog("Appearance")` with System default / Light / Dark + check mark
3. **Notifications** (`SwitchListTile`)
   - Icon: `Icons.notifications_outlined`
   - Subtitle: "Alerts when a member needs help"
   - Toggle → `_setNotifications(enabled)`
   - ON: `messaging.register()` + `saveFcmToken`
   - OFF: `clearFcmToken` + `messaging.deleteToken()`
4. **Privacy Controls**
   - Icon: `Icons.shield_outlined`
   - Subtitle: "Pause sharing or clear history"
   - Tap → `/privacy`

#### Section "General"
5. **Location Refresh**
   - Icon: `Icons.sync`
   - Subtitle: "Every 5 seconds" / "Every 10 seconds" / "Every 30 seconds" / "Every 1 min"
   - Tap → `_showRefreshSheet()` → bottom sheet with options `[5, 10, 30, 60]`, current par check
   - Select → `setRefreshSeconds` + `locationController.restart()`
6. **Alerts History**
   - Icon: `Icons.history`
   - Subtitle: "Past SOS alerts"
   - Tap → `/alerts`
7. **Change Email**
   - Icon: `Icons.email_outlined`
   - Subtitle: "Update your account email"
   - Tap → `/change-email`
8. **Change Password**
   - Icon: `Icons.password_outlined`
   - Subtitle: "Update your account password"
   - Tap → `/change-password`
9. **Delete Profile**
   - Icon: `Icons.delete_outline` (red), title red
   - Tap → `_DeleteConfirmDialog`
   - Dialog: "Delete Profile?" + warning + Cancel / Delete (spinner while busy)
   - Delete → `authController.deleteAccount()`

#### Section "Others"
10. **Share**
    - Icon: `Icons.share`
    - Enabled only if `AppConfig.appLink.isNotEmpty`
    - Tap → `_shareApp()` (`SharePlus`)
11. **Rate us**
    - Icon: `Icons.star_border`
    - Enabled only if `AppConfig.playStoreUrl.isNotEmpty`
    - Tap → `_launch(playStoreUrl)`
12. **Feedback**
    - Icon: `Icons.feedback_outlined`
    - Enabled only if `AppConfig.feedbackEmail.isNotEmpty`
    - Tap → `mailto:feedbackEmail`

#### Section "About"
13. **Help & Support**
    - Icon: `Icons.help_outline`
    - Enabled only if `AppConfig.feedbackEmail.isNotEmpty`
    - Tap → `mailto:feedbackEmail`
14. **Terms of Service**
    - Icon: `Icons.description_outlined`
    - Enabled only if `AppConfig.termsUrl.isNotEmpty`
    - Tap → `_launch(termsUrl)`
15. **Privacy Policy**
    - Icon: `Icons.privacy_tip_outlined`
    - Enabled only if `AppConfig.privacyPolicyUrl.isNotEmpty`
    - Tap → `_launch(privacyPolicyUrl)`
16. **About**
    - Icon: `Icons.info_outline`
    - Subtitle: "App version and details"
    - Tap → `_showAbout()` → dialog with app name, version/build, description, Close

#### Bottom
- "Logout" `OutlinedButton.icon` (red) → `_LogoutConfirmDialog` → `signOut()`
- `BannerAdWidget(AdUnits.settingsBanner)`

#### Functions
- `initState()` — lifecycle observer + permissions refresh
- `dispose()`
- `didChangeAppLifecycleState(state)` — resumed par permissions refresh
- `_refreshPermissions()`
- getters: `_locationLabel`, `_locationColor`, `_locationIcon`
- `_intervalLabel(seconds)`
- `_showRefreshSheet()`
- `_shareApp()`
- `_launch(url)`
- `_themeModeLabel(mode)`
- `_pickThemeMode(current)`
- `_setNotifications(enabled)`
- `_showAbout()`
- `_confirmDelete()`
- `_confirmLogout()`
- `build()`
- `_sectionHeader(context, title)`
- `_profileHeader(context)`
- `_LogoutConfirmDialog.build()`
- `_DeleteConfirmDialogState._delete()`
- `_DeleteConfirmDialogState.build()`

### 6.12 View Profile — `lib/features/settings/view_profile_screen.dart`
- `ViewProfileScreen` → `_ViewProfileScreenState`
- AppBar: "My Profile" / "Edit Profile"
- View mode:
  - `ProfileAvatar(radius: 56)`
  - Name
  - Email
  - Phone (optional, `Icons.phone_outlined`)
  - "Edit Profile" `CustomButton` → `_startEdit()`
- Edit mode:
  - Avatar + camera button
  - "Remove photo" (agar photo ho)
  - Display name field (max 40)
  - Phone (optional) field
  - "Save" `CustomButton` → `_save()`
  - "Cancel" `TextButton`
- Photo sheet:
  - "Choose from gallery" (`ImageSource.gallery`)
  - "Take a photo" (`ImageSource.camera`)
  - Picker: `maxWidth: 512`, `imageQuality: 70`
- Functions:
  - `dispose()`
  - `_startEdit(currentName, currentPhotoUrl, phone)`
  - `_cancelEdit()`
  - `_showPhotoSheet()`
  - `_save()` → `updateProfile()` + invalidate providers
  - `build()`
  - `_viewBody(theme, photoUrl, name, email, phone)`
  - `_editBody(theme)`
  - `_editAvatar()`

### 6.13 Privacy Controls — `lib/features/settings/privacy_controls_screen.dart`
- `PrivacyControlsScreen` → `_PrivacyControlsScreenState`
- AppBar: "Privacy Controls"
- Section "Sharing":
  - `SwitchListTile("Share my location")`
  - Subtitle: "Your location updates are live" / "Location sharing is paused"
  - Toggle → `_toggleSharing()` → `locationController.resume()` / `stop()`
- Section "Location History":
  - `ListTile("Clear my location history")`
  - Subtitle: "Removes your saved location from the map" / "Clearing..."
  - Tap → confirm dialog "Clear location history?" → `clearHistory()`
  - Success text: "Location history cleared."
  - Error text (red)
- Functions: `_toggleSharing(on)`, `_clearHistory()`, `build()`, `_sectionHeader()`

### 6.14 Alerts History — `lib/features/settings/alerts_screen.dart`
- `AlertsScreen` → `_AlertsScreenState`
- AppBar: "Alerts History" + trash icon ("Clear history")
- Filters: `ChoiceChip` — All / Active / Resolved
- States:
  - empty → "No alerts yet. Send an SOS and it will appear here."
  - error → "Could not load alerts..."
  - no filter match → "No alerts match this filter."
- `_AlertCard`:
  - Avatar: check (resolved) / SOS (active)
  - Name, group name, sent/resolved time
  - Badge: "Resolved" / "Active"
  - Map icon
  - Tap → `/alert-map?lat=&lng=&name=`
- Clear dialog:
  - "Clear alerts history?" + warning + Cancel / Clear (spinner)
  - Clear → `alertController.clearHistory()`
- Functions: `_groupNameFor()`, `_apply()`, `_confirmClear()`, `build()`, `_filterChip()`; `_AlertCard.build()`; `_ClearAlertsDialogState._clear()`, `build()`

### 6.15 Alert Map — `lib/features/settings/alert_map_screen.dart`
- `AlertMapScreen(latitude, longitude, name)` (Stateless)
- AppBar: name ya "Alert location"
- `GoogleMap` zoom 16, red marker, zoom controls enabled
- Functions: `build()`

### 6.16 Members — `lib/features/settings/members_screen.dart`
- `MembersScreen(groupId)` → `_MembersScreenState`
- AppBar: "Members"
- Header: group name + member count
- Search field (sirf jab members > 3) — "Search members"
- `_MemberTile`:
  - Avatar, name, "Owner"/"You" badge
  - Subtitle: "This is you" / "No location shared yet" / "Last seen ..."
  - Tap → member bottom sheet
  - Trailing `PopupMenuButton` (owner only, for other members): "Make owner", "Remove member"
- Member bottom sheet:
  - Avatar, name, role ("Group owner" / "You (member)" / "Member")
  - Last seen / "No location shared yet"
  - "View on map" `FilledButton.icon` (agar location ho) → `/alert-map`
- Footer:
  - Owner → "Delete group" `OutlinedButton.icon` (red)
  - Member → "Leave group"
- Dialogs: Leave group? / Delete group? / Remove member? / Transfer ownership?
- Functions:
  - `dispose()`
  - `_confirm({title, message, confirmLabel, confirmColor})`
  - `_leave(group)` → `leaveGroup()`
  - `_delete(group)` → `deleteGroup()`
  - `_remove(group, uid, name)` → `removeMember()`
  - `_makeOwner(group, uid, name)` → `transferOwnership()`
  - `_openMember({...})`
  - `build()`
  - `_header(context, group)`
  - `_MemberTile.build()`
  - `_MemberTile._badge()`

### 6.17 Change Email — `lib/features/settings/change_email_screen.dart`
- `ChangeEmailScreen` → `_ChangeEmailScreenState`
- AppBar: "Change Email"
- Widgets:
  - Security note
  - "Current: email"
  - Current password field (visibility toggle)
  - New email field
- Button: "Update Email" `CustomButton` → `_submit(currentEmail)`
- Flow: reauthenticate → `verifyBeforeUpdateEmail` → dialog "Check your inbox" → back
- Validation: password non-empty, email regex, same email check
- Functions: `dispose()`, `_validateEmail()`, `_submit(currentEmail)`, `build()`

### 6.18 Change Password — `lib/features/settings/change_password_screen.dart`
- `ChangePasswordScreen` → `_ChangePasswordScreenState`
- AppBar: "Change Password"
- Widgets:
  - Security note
  - Current password field (visibility toggle)
  - New password field (visibility toggle)
  - Confirm new password field
- Button: "Update Password" `CustomButton` → `_submit()`
- Flow: reauthenticate → update → dialog "Password changed" → back
- Validation: current non-empty, `PasswordValidator`, confirm match
- Functions: `dispose()`, `_submit()`, `build()`

### 6.19 Not Found — `lib/features/error/not_found_screen.dart`
- `NotFoundScreen(location)` (Stateless)
- AppBar: empty
- `Icons.explore_off_outlined` (72)
- "Page not found"
- "We couldn't find {location}."
- "Go home" `CustomButton` → `/home`
- Functions: `build()`

---

## 7. Providers / State (`lib/providers/`)

### `auth_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `authRepositoryProvider` | `Provider<AuthRepository>` | auth repo |
| `messagingServiceProvider` | `Provider<MessagingService>` | FCM service |
| `authStateProvider` | `StreamProvider<String?>` | current uid |
| `emailVerifiedProvider` | `FutureProvider<bool>` | email verified |
| `userNameProvider(uid)` | `FutureProvider.family<String?, String>` | user name |
| `userDocProvider(uid)` | `FutureProvider.family<Map?, String>` | raw user doc |
| `userProfileProvider(uid)` | `FutureProvider.family<UserProfile?, String>` | typed profile |
| `authControllerProvider` | `AsyncNotifierProvider<AuthController, void>` | auth actions |

`AuthController` methods:
- `build()`
- `signIn({email, password})`
- `signUp({email, password, name})`
- `updateProfile({name, photoFilePath, phone, removePhoto})`
- `changeEmail({currentPassword, newEmail})`
- `changePassword({currentPassword, newPassword})`
- `deleteAccount()`
- `sendPasswordReset(email)`
- `resendVerification()`
- `signOut()` — clear FCM token + delete token + sign out

### `group_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `firestoreServicesProvider` | `Provider<FirestoreServices>` | Firestore wrapper |
| `groupRepositoryProvider` | `Provider<GroupRepository>` | group repo |
| `myGroupsStreamProvider` | `StreamProvider<List<GroupModel>>` | my groups |
| `groupStreamProvider(groupId)` | `StreamProvider.family<GroupModel, String>` | single group |
| `groupControllerProvider` | `AsyncNotifierProvider<GroupController, void>` | group actions |
| `selectedGroupIdProvider` | `NotifierProvider<SelectedGroupId, String?>` | active group |
| `memberGroupsProvider(uid)` | `StreamProvider.family<List<GroupModel>, String>` | groups of a uid |

`GroupController` methods:
- `build()`
- `createGroup({name, category})`
- `renameGroup({groupId, name})`
- `joinGroup({inviteCode})`

`SelectedGroupId`:
- `build()`
- `select(id)`

### `location_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `locationServicesProvider` | `Provider<LocationServices>` | location service |
| `locationRepositoryProvider` | `Provider<LocationRepository>` | location repo |
| `myLocationProvider` | `StreamProvider<LocationPoint?>` | my latest point |
| `isSharingProvider` | `NotifierProvider<IsSharing, bool>` | sharing flag |
| `locationControllerProvider` | `AsyncNotifierProvider<LocationController, void>` | tracking control |

`IsSharing`: `build()`, `on()`, `off()`

`LocationController`:
- `build()`
- `start()` — paused check → permission → notification permission → background access → `BackgroundTracking.start` → sharing on
- `resume()` — unpause + start
- `restart()` — stop → 600ms delay → start
- `stop()` — pause + background stop + sharing off
- `clearHistory()` — delete location doc + invalidate

### `member_locations_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `memberLocationsProvider` | `StreamProvider<Map<String, LocationPoint>>` | active group's member locations |
| `groupMemberLocationsProvider(groupId)` | `StreamProvider.family<Map<String, LocationPoint>, String>` | specific group locations |

Helpers:
- `_locationsFor(memberIds, repo)` — null filter
- `_combineMemberLocations(memberIds, repo)` — merge per-uid streams
- `_withRetry(source)` — 5 attempts, exponential backoff (500ms × 2^attempt); inner `connect(attempt)`

### `alert_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `alertRepositoryProvider` | `Provider<AlertRepository>` | alerts repo |
| `alertHistoryProvider` | `StreamProvider<List<AlertRecord>>` | my alerts |
| `alertControllerProvider` | `AsyncNotifierProvider<AlertController, void>` | clear history |

`AlertController`: `build()`, `clearHistory()`

### `settings_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | prefs (main override) |
| `settingsProvider` | `NotifierProvider<SettingsController, UserSettings>` | user settings |

`UserSettings` fields:
- `notificationsEnabled` (default `true`)
- `refreshSeconds` (default `10`)
- `themeMode` (default `system`)
- `copyWith(...)`

`SettingsController`:
- `build()` — prefs read
- `setNotifications(bool)`
- `setRefreshSeconds(int)`
- `setThemeMode(ThemeMode)`
- `_decodeThemeMode(String?)`

### `notification_provider.dart`
- `notificationServiceProvider` — `Provider<NotificationService>` (main override)

### `campaign_banner_provider.dart`
| Provider | Type | Purpose |
|---|---|---|
| `campaignBannerProvider` | `NotifierProvider<CampaignBannerNotifier, CampaignBannerState?>` | current campaign banner |

`CampaignBannerState`: `title`, `body`
`CampaignBannerNotifier`: `build()` → null, `show({title, body})`, `dismiss()`

### `app_startup_provider.dart`
- `minimumSplashProvider` — `FutureProvider<void>`, 1.8s timer + `Completer`, timer cancel on dispose

---

## 8. Repositories (`lib/data/repositories/`)

### `AuthRepository`
- `AuthRepository(authService, firestore)`
- `authStateChanges()` → `Stream<String?>`
- `signUp({email, password, name})` → user doc create + verification email
- `signIn({email, password})`
- `signOut()`
- `updateProfile({name, photoFilePath, phone, removePhoto})` → base64 photo data URI + auth display name
- `changeEmail({currentPassword, newEmail})` → reauth + `verifyBeforeUpdateEmail`
- `changePassword({currentPassword, newPassword})` → reauth + update
- `saveFcmToken(uid, token)` → `users/{uid}.fcmToken`
- `clearFcmToken(uid)` → delete field
- `sendPasswordReset(email)`
- `sendEmailVerification()`
- `refreshEmailVerified()` → reload + return
- `deleteAccount()` → leave/transfer/delete groups, delete location + user doc, delete auth
- `userName(uid)`
- `userDoc(uid)`
- `userProfile(uid)`
- `_mapAuthError(FirebaseAuthException)` → `AuthFailure` messages

### `GroupRepository`
- `GroupRepository(firestore, authService)`
- `createGroup({name, category})` → unique doc id via transaction, retry up to 50
- `_reserve(docId, template)` → transaction create or null
- `uniqueId({name, category})` → `{categorySlug}_{nameSlug}`
- `slug(value)`
- `isNameTaken({name, category})`
- `suggestNames({name, category, count = 2})`
- `joinGroup({inviteCode})` → find by code, member checks, arrayUnion
- `sendSos({groupId, latitude, longitude})` → `groups/{id}.sos` + new `alerts` doc
- `resolveSos(groupId)` → delete `sos` + mark latest open alert resolved
- `renameGroup({groupId, name})` → owner only
- `transferOwnership({groupId, newOwnerId})` → owner only
- `removeMember({groupId, uid})` → owner only
- `leaveGroup(groupId)` → arrayRemove self
- `deleteGroup(groupId)` → owner only
- `groupsContaining(uid)` → stream
- `getUserGroups()` → stream (empty if logged out)
- `groupStream(groupId)` → single group stream
- `_firestoreMessage(FirebaseException)`

### `LocationRepository`
- `LocationRepository(firestore, authService)`
- `setSharingPaused(bool)` → `users/{uid}.sharingPaused`
- `isSharingPaused()` → bool (default true on error)
- `clearHistory()` → delete `location_points/{uid}`
- `latestPoint(uid)` → stream of `LocationPoint?`
- `_firestoreMessage(FirebaseException)`

### `AlertRepository`
- `AlertRepository(firestore)`
- `clearMyAlerts(uid)` → delete all `alerts` where uid
- `myAlerts(uid)` → stream sorted newest first

---

## 9. Services (`lib/data/services/`)

### `FirebaseAuthServices`
- `authStateChanges()` → `Stream<User?>`
- `signUp({email, password, name})` + displayName
- `signIn({email, password})`
- `signOut()`
- `updateDisplayName(name)`
- `reauthenticate({email, password})`
- `updatePassword(newPassword)`
- `deleteAccount()`
- `verifyBeforeUpdateEmail(email)`
- `sendPasswordResetEmail(email)`
- `sendEmailVerification()`
- `refreshEmailVerified()` → reload + bool
- getters: `currentUserId`, `currentUserName`, `currentUserEmail`

### `FirestoreServices`
- `setDoc(path, data, {merge = false})`
- `updateDoc(path, data)`
- `deleteDoc(path)`
- `docStream(path)` → `Stream<DocumentSnapshot>`
- `getDoc(path)` → `Map?`
- `collection(path)` → `CollectionReference`
- `runTransaction(action)`
- `transaction<T>(action)`

### `LocationServices`
- `ensurePermission()` → check/request location; whileInUse/always true
- `ensureNotificationPermission()` → request notification
- `ensureBackgroundAccess()` → request `locationAlways` + `ignoreBatteryOptimizations`
- `currentPoint()` → `LocationPoint` (high accuracy, 10s limit)
- `_toPoint(position)`

### `BackgroundTracking` / `background_service.dart`
Constants:
- `locationSharingChannelId = 'location_sharing'`
- `locationSharingNotificationId = 771177`
- prefs keys: `bgTrackingEnabled`, `bgTrackingInterval`, `bgTrackingMinMeters`

Functions:
- `initializeBackgroundService()` — channel + `FlutterBackgroundService.configure` (foreground, location type, autoStartOnBoot)
- `_createNotificationChannel()` — low importance channel
- `BackgroundTracking.start({uid, seconds})` → prefs + start service
- `BackgroundTracking.stop()` → prefs false + `stopService`
- `BackgroundTracking.isRunning()`
- `backgroundServiceEntry(service)` — foreground/background handlers, Firebase init, enabled check, wait user, start tracking
- `_waitForUser()` — current user or auth stream up to 15s
- `_settings(seconds, minMeters)` → `AndroidSettings(high, distanceFilter, intervalDuration)`
- `_startTracking()` — position stream listen `_save`
- `_stopTracking()` — cancel subscription
- `_save(position)` — battery + write `location_points/{uid}`

### `MessagingService`
- getter `onTokenRefresh` → `Stream<String>`
- getter `onMessageOpenedApp` → `Stream<RemoteMessage>`
- `getInitialMessage()` → `Future<RemoteMessage?>` (cold-start tap)
- `register()` → request permission, foreground presentation options, `getToken()`
- `deleteToken()`

### `NotificationService`
- channel: `sos_alerts` ("SOS alerts", description "Emergency alerts from your group members.", importance max)
- channel: `campaigns` ("Announcements", description "News, tips and announcements from Family Locator.", importance high)
- `_ready` flag
- `init()` — initialize plugin + create dono channels
- `requestPermission()` — request notifications permission
- `showSos({senderName, groupName})` — id 1, title "SOS from X", body "X needs help in Y.", payload `sos`
- `showCampaign({title, body})` — timestamp-based id (SOS id 1 se alag), channel `campaigns`, payload `campaign`

---

## 10. Models (`lib/data/models/`)

### `UserProfile`
Fields: `uid`, `name`, `email`, `photoUrl?`, `phone?`
Methods: `fromJson`, `toJson`, `copyWith`

### `GroupModel`
Fields: `id`, `name`, `category`, `inviteCode`, `ownerId`, `memberIds[]`, `createdAt`, `sos?`
Methods: `fromJson`, `toJson`, `containsMember(uid)`, `copyWith`

### `LocationPoint`
Fields: `latitude`, `longitude`, `timestamp`, `batteryLevel?`, `accuracy?`
Methods: `fromJson`, `toJson`

### `SosAlert`
Fields: `uid`, `name`, `latitude`, `longitude`, `createdAt`
Methods: `fromJson`, `toJson`

### `AlertRecord`
Fields: `id`, `groupId`, `uid`, `name`, `latitude`, `longitude`, `createdAt`, `resolvedAt?`
Methods: `fromJson(id, json)`, `toJson`

---

## 11. Core (`lib/core/`)

### `constants/app_config.dart`
- `locationUpdateInterval = 30s`
- `staleLocationAfter = 5 min`
- `minDistanceToUpload = 50.0`
- `inviteCodelength = 6`
- `defaultMapZoom = 15.0`
- `appLink = ''` (khaali)
- `playStoreUrl = ''` (khaali)
- `feedbackEmail = ''` (khaali)
- `termsUrl = ''` (khaali)
- `privacyPolicyUrl = ''` (khaali)

### `constants/app_strings.dart`
- `appName = 'Family Locator'`
- `loginTitle = 'Welcome Back!'`

### `constants/app_colors.dart`
`AppColors`: primary `#2E7D32`, primaryContainer `#A5D6A7`, background `#F5F5F5`, surface `#FFFFFF`, textDark `#1B1B1B`, textLight `#616161`, error `#D32F2F`, success `#388E3C`, warning `#FBC02D`, secondary `#EF6C00`.
`AppPalette` (ThemeExtension): light/dark palettes; `copyWith`, `lerp`.
Extension `BuildContext.palette`.

### `constants/group_categories.dart`
`GroupCategories`: Friends, School, Office, Travel, Custom; `all`; `contains(value)`; `normalize(value)`.

### `constants/ad_units.dart`
- `groupsBanner = 'ca-app-pub-3940256099942544/9214589741'`
- `settingsBanner = 'ca-app-pub-3940256099942544/6300978111'`
(donon Google test units)

### `errors/failure.dart`
`Failure` (message) + `AuthFailure`, `NetworkFailure`, `FirestoreFailure`, `GroupNotFoundFailure`, `GroupAlreadyMemberFailure`, `LocationPermissionFailure`.

### `theme/app_theme.dart`
`AppTheme.light`, `AppTheme.dark`, `_build(palette, brightness)`:
- ColorScheme from seed
- AppBar (surface, elevation 0)
- Dialog/BottomSheet themes
- Divider theme
- TextTheme sizes: titleLarge 20/w600, headlineSmall 18/w600, titleMedium 16/w600, titleSmall 14/w600, labelLarge 16/w600, labelMedium 13/w700, labelSmall 12/w400, bodyLarge 16/w400, bodyMedium 14/w400, bodySmall 13/w400
- InputDecoration (filled, rounded 14, green borders)
- ElevatedButton (height 52, radius 14, 16/w600)
- OutlinedButton, TextButton, ChipTheme

### `utils/code_generator.dart`
- `_alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'`
- `generate()` — secure random 6-char code

### `utils/date_formatter.dart`
- `lastSeen(time)` → "just now" / "Xm ago" / "Xh ago" / "Xd ago"
- `timeOnly(time)` → "HH:mm"

### `utils/distance_calculator.dart`
- `metersBetween(lat1, lng1, lat2, lng2)`
- `labelBetween(...)` → "X m" / "X.X km"

### `utils/invite_share.dart`
- `shareInvite({groupName, inviteCode})` → SharePlus
- `copyInviteCode(context, inviteCode)` → clipboard + SnackBar

### `utils/password_validator.dart`
- `validate(password)`:
  - min 12 characters
  - 1 uppercase
  - 1 digit
  - 1 special (`@#$&`)

---

## 12. Backend — Cloud Functions (`functions/index.js`)

- Runtime: Node.js 20 (package.json)
- Deps: `firebase-admin` ^12.7.0, `firebase-functions` ^6.1.0
- `admin.initializeApp()`
- `setGlobalOptions({ region: "us-central1" })`
- Export `sosPush` = `onDocumentUpdated("groups/{groupId}")`
  - Agar `after.sos` naya hai (createdAt changed) → members ko SOS push (`type: "sos"`, data me `groupId`, `uid`, `name`, `latitude`, `longitude`)
  - Agar `sos` delete hua → "SOS resolved" push (`type: "sos_resolved"`)
- `sendToMembers(memberIds, excludeUid, payload)`:
  - sender ko chhor kar baqi members ke `users/{uid}.fcmToken` collect
  - `sendEachForMulticast` with notification + data
  - Android priority high + channel `sos_alerts`
  - stale token errors (`registration-token-not-registered`, `invalid-registration-token`) par `fcmToken` delete

Deploy (Blaze required):
```
firebase login
firebase use family-locator-4551f
cd functions && npm install
cd ..
firebase deploy --only functions
```

---

## 13. Firestore Data Model

### `users/{uid}`
- `uid`
- `name`
- `email`
- `photoUrl` (base64 data URI ya empty)
- `phone`
- `fcmToken` (server push ke liye)
- `sharingPaused` (bool)

### `groups/{groupId}`
- doc id = `{slug(category)}_{slug(name)}` (`_1`, `_2` suffix on collision)
- `id`
- `name`
- `category`
- `inviteCode` (6 chars)
- `ownerId`
- `memberIds[]`
- `createdAt` (ISO string)
- `sos` (optional map):
  - `uid`
  - `name`
  - `latitude`
  - `longitude`
  - `createdAt` (ISO string)

### `location_points/{uid}`
- `latitude`
- `longitude`
- `timestampMs`
- `batteryLevel`
- `accuracy`

### `alerts/{autoId}`
- `groupId`
- `uid`
- `name`
- `latitude`
- `longitude`
- `createdAt` (ISO string)
- `resolvedAt` (ISO string ya null)

---

## 14. Android Manifest

### Permissions
- `CAMERA`
- `INTERNET`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `POST_NOTIFICATIONS`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `WAKE_LOCK`
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- `RECEIVE_BOOT_COMPLETED`

### Application
- Label: `familylocator`
- Maps API key via `${MAPS_API_KEY}`
- `MainActivity` (singleTop, launchMode)
- Background service: `id.flutter.flutter_background_service.BackgroundService` (`foregroundServiceType="location"`)
- AdMob App ID: `ca-app-pub-3940256099942544~3347511713` (test)
- Default FCM channel: `com.google.firebase.messaging.default_notification_channel_id` = `campaigns`
- Queries: `PROCESS_TEXT`

---

## 15. Notification / FCM Flow

### SOS (server-triggered)
1. Startup: local notification permission + `sos_alerts` + `campaigns` channels.
2. Login/HomeShell: `MessagingService.register()` → token → `users/{uid}.fcmToken`.
3. Token refresh: `onTokenRefresh` → token update.
4. SOS send: `sendSos()` Firestore me `groups/{id}.sos` + `alerts` doc likhta hai.
5. Cloud Function trigger: members ko FCM notification bhejta hai (sender ke ilawa).
6. Foreground in-app: Map screen Firestore listener → `_notifySosIfNeeded()` → local `showSos()`.
7. Settings toggle OFF: token clear + delete (server push band).
8. Tap handling: `onMessageOpenedApp` (background tap) + `getInitialMessage()` (cold start) → `HomeShell._openNotification()` → SOS par `/alert-map?lat=&lng=&name=` push; coords missing ho to `/alerts`.

### Campaigns (Firebase Console)
1. Console: Engage → Messaging → New campaign → Firebase Notification message.
2. Android Notification Channel: `campaigns` (manifest default bhi `campaigns`); Custom data: `type` = `campaign`.
3. App band/background: OS notification khud dikhata hai (koi background handler nahi chahiye).
4. App khuli: `FirebaseMessaging.onMessage` → `type == "campaign"` + notifications ON → local `showCampaign()` + `campaignBannerProvider.show()`; banner HomeShell ke top par teeno tabs ke upar slide hota hai, 8s baad auto-dismiss (X se bhi band).
5. Campaign tap: koi special navigation nahi (app khulti hai, `_openNotification` sirf `sos` handle karta hai).
6. Audience: console sirf app/topic/segment target kar sakta hai; group-wise targeting ke liye topic subscription chahiye (abhi nahi).

---

## 16. Background Location Flow

1. `HomeScreen.initState()` → `locationController.start()`.
2. `isSharingPaused` check (`users/{uid}.sharingPaused`).
3. Permission: location → notification → always location → battery optimization.
4. `BackgroundTracking.start(seconds)` → prefs (`bgTrackingEnabled`, `bgTrackingInterval`) + foreground service.
5. `backgroundServiceEntry` → Firebase init → user wait → `_startTracking()`.
6. Geolocator `AndroidSettings`:
   - `accuracy: high`
   - `distanceFilter: 50 m`
   - `intervalDuration: refreshSeconds` (default 10s, settings 5/10/30/60)
7. Har update par `_save()` → battery level + `location_points/{uid}` write.
8. Stop → prefs false + service stop + sharing off.
9. Frontground service notification: channel `location_sharing`, title "Family Locator", text "Sharing your location".

---

## 17. Local Settings Keys (`SharedPreferences`)

| Key | Type | Default |
|---|---|---|
| `notificationsEnabled` | bool | `true` |
| `refreshSeconds` | int | `10` |
| `themeMode` | string | `system` |
| `bgTrackingEnabled` | bool | — |
| `bgTrackingInterval` | int | — |
| `bgTrackingMinMeters` | int | — |

---

## 18. Ads (AdMob)

- SDK: `google_mobile_ads` 9.1.0
- Initialized in `main.dart`
- Manifest App ID: test `ca-app-pub-3940256099942544~3347511713`
- Placements:
  1. All Groups screen — banner (below Create/Join) → `AdUnits.groupsBanner` (adaptive test banner)
  2. Settings bottom — banner → `AdUnits.settingsBanner` (fixed test banner)
- Rule: ek ad unit sirf ek jagah.
- `BannerAdWidget` reserved height 50px jab tak load na ho.

---

## 19. Tests (`test/`)

- `test/code_generator_test.dart` — code generator
- `test/distance_calculator_test.dart` — distance label/meters
- `test/qr_dialog_test.dart` — QR dialog
- `test/widget_test.dart` — app widget smoke test

Total: 10 tests (last run 10/10 pass).

---

## 20. Known Gaps / Placeholders

1. **AppConfig URLs khaali hain** — Share, Rate us, Feedback, Help, Terms, Privacy Policy disabled hain.
2. **AdMob test IDs** — release se pehle real App ID + unit IDs chahiye.
3. **Cloud Function deploy nahi hui** — Blaze plan chahiye.
4. **Campaign audience group-wise nahi** — console sirf app/topic/segment target karta hai; group topics abhi implement nahi.
5. **In-app campaign banner** — sirf foreground me, HomeShell mounted ho tab; top overlay, 8s auto-dismiss.
6. **Profile photo** — Firebase Storage ke bajaye base64 data URI Firestore me save hoti hai.
7. **`copyInviteCode` SnackBar** — baqi app me SnackBar banned hai, sirf yahan maujood hai.
8. **iOS support** — hata di gayi; sirf Android.
9. **`location_repository.dart`** — `latestPoint` me formatting thori odd hai (functionally theek hai).

---

## 21. Quick File Index

```
lib/
  main.dart
  firebase_options.dart
  core/
    constants/ (ad_units, app_colors, app_config, app_strings, group_categories)
    errors/failure.dart
    router/app_router.dart
    theme/app_theme.dart
    utils/ (code_generator, date_formatter, distance_calculator, invite_share, password_validator)
  data/
    models/ (alert_record, group_model, location_point, sos_alert, user_model)
    repositories/ (alert, auth, group, location)
    services/ (background_service, firebase_auth_services, firestore_services,
               location_service, messaging_service, notification_service)
  features/
    auth/ (login, signup, forgot_password)
    error/not_found_screen.dart
    group_setup/ (choose_group, create_group, groups_screen, invite, join_group)
    home_map/home_map_screen.dart
    settings/ (alerts, alert_map, change_email, change_password, members,
               privacy_controls, settings_screen, view_profile)
    shell/home_shell.dart
    splash/splash_screen.dart
  providers/ (alert, app_startup, auth, campaign_banner, group, location,
              member_locations, notification, settings)
  shared_widgets/ (banner_ad_widget, campaign_banner, custom_button, error_view,
                   loading_indicator, offline_view, profile_avatar)
functions/
  index.js
  package.json
  .gitignore
test/
  code_generator_test.dart
  distance_calculator_test.dart
  qr_dialog_test.dart
  widget_test.dart
```
