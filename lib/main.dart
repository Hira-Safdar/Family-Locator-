import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/ads_service.dart';
import 'data/services/background_service.dart';
import 'data/services/notification_service.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';
import 'core/constants/app_strings.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  await initializeBackgroundService();
  await AdsService.instance.initialize();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const FamilyApp(),
    ),
  );
}

class FamilyApp extends ConsumerWidget {
  const FamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(
      settingsProvider.select((settings) => settings.themeMode),
    );
    final locale = ref.watch(
      settingsProvider.select((settings) => settings.locale),
    );
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
