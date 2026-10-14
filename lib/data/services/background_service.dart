import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_config.dart';
import '../../firebase_options.dart';

const String locationSharingChannelId = 'location_sharing';
const int locationSharingNotificationId = 771177;

const String _enabledKey = 'bgTrackingEnabled';
const String _intervalKey = 'bgTrackingInterval';
const String _minMetersKey = 'bgTrackingMinMeters';

StreamSubscription<Position>? _positionSubscription;

Future<void> initializeBackgroundService() async {
  await _createNotificationChannel();
  await FlutterBackgroundService().configure(
    androidConfiguration: AndroidConfiguration(
      onStart: backgroundServiceEntry,
      autoStart: false,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: locationSharingChannelId,
      initialNotificationTitle: 'Family Locator',
      initialNotificationContent: 'Sharing your location',
      foregroundServiceNotificationId: locationSharingNotificationId,
      foregroundServiceTypes: const [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: backgroundServiceEntry,
      onBackground: backgroundServiceOnBackground,
    ),
  );
}

Future<void> _createNotificationChannel() async {
  final android = FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      locationSharingChannelId,
      'Location sharing',
      description:
          'Shown while your location is being shared with your family.',
      importance: Importance.low,
    ),
  );
}

class BackgroundTracking {
  static Future<void> start({String? uid, required int seconds}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_intervalKey, seconds);
    await FlutterBackgroundService().startService();
  }

  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
    FlutterBackgroundService().invoke('stopService');
  }

  static Future<bool> isRunning() => FlutterBackgroundService().isRunning();
}

@pragma('vm:entry-point')
Future<void> backgroundServiceEntry(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((_) async {
    await _stopTracking();
    await service.stopSelf();
  });

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_enabledKey) != true) {
    await service.stopSelf();
    return;
  }

  await _waitForUser();
  await _startTracking();
}

Future<bool> backgroundServiceOnBackground(ServiceInstance service) async {
  return true;
}

Future<User?> _waitForUser() async {
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) return auth.currentUser;
  try {
    return await auth
        .authStateChanges()
        .firstWhere((user) => user != null)
        .timeout(const Duration(seconds: 15));
  } catch (_) {
    return null;
  }
}

LocationSettings _settings(int seconds, int minMeters) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.other,
      distanceFilter: minMeters,
      pauseLocationUpdatesAutomatically: false,
      allowBackgroundLocationUpdates: true,
    );
  }
  return AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: minMeters,
    intervalDuration: Duration(seconds: seconds),
  );
}

Future<void> _startTracking() async {
  await _positionSubscription?.cancel();
  final prefs = await SharedPreferences.getInstance();
  final seconds =
      prefs.getInt(_intervalKey) ?? AppConfig.locationUpdateInterval.inSeconds;
  final minMeters =
      prefs.getInt(_minMetersKey) ?? AppConfig.minDistanceToUpload.round();

  _positionSubscription = Geolocator.getPositionStream(
    locationSettings: _settings(seconds, minMeters),
  ).listen(_save, onError: (_) {}, cancelOnError: false);
}

Future<void> _stopTracking() async {
  await _positionSubscription?.cancel();
  _positionSubscription = null;
}

Future<void> _save(Position position) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_enabledKey) != true) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  int? battery;
  try {
    battery = await Battery().batteryLevel;
  } catch (_) {}
  try {
    await FirebaseFirestore.instance
        .collection('location_points')
        .doc(uid)
        .set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestampMs': DateTime.now().millisecondsSinceEpoch,
          'batteryLevel': battery,
          'accuracy': position.accuracy,
        });
  } catch (_) {}
}
