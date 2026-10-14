import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failure.dart';
import '../data/models/location_point.dart';
import '../data/repositories/location_repository.dart';
import '../data/services/background_service.dart';
import '../data/services/firebase_auth_services.dart';
import '../data/services/firestore_services.dart';
import '../data/services/location_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

final locationServicesProvider = Provider<LocationServices>((ref) {
  return LocationServices();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(FirestoreServices(), FirebaseAuthServices());
});

final myLocationProvider = StreamProvider<LocationPoint?>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.empty();
  return ref.watch(locationRepositoryProvider).latestPoint(uid);
});

class IsSharing extends Notifier<bool> {
  @override
  bool build() => false;

  void on() => state = true;
  void off() => state = false;
}

final isSharingProvider = NotifierProvider<IsSharing, bool>(IsSharing.new);

class LocationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> start() async {
    state = const AsyncLoading();
    final repo = ref.read(locationRepositoryProvider);
    final paused = await repo.isSharingPaused();
    if (paused) {
      ref.read(isSharingProvider.notifier).off();
      state = const AsyncData(null);
      return;
    }
    final services = ref.read(locationServicesProvider);
    final allowed = await services.ensurePermission();
    if (!allowed) {
      state = AsyncError(
        LocationPermissionFailure('Location Permission not granted.'),
        StackTrace.current,
      );
      return;
    }
    final seconds = ref.read(settingsProvider).refreshSeconds;
    final uid = ref.read(authStateProvider).value;
    await services.ensureNotificationPermission();
    await services.ensureBackgroundAccess();
    await BackgroundTracking.start(uid: uid, seconds: seconds);
    ref.read(isSharingProvider.notifier).on();
    state = const AsyncData(null);
  }

  Future<void> resume() async {
    await ref.read(locationRepositoryProvider).setSharingPaused(false);
    await start();
  }

  Future<void> restart() async {
    if (!ref.read(isSharingProvider)) return;
    await BackgroundTracking.stop();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await start();
  }

  Future<void> stop() async {
    try {
      await ref.read(locationRepositoryProvider).setSharingPaused(true);
    } finally {
      await BackgroundTracking.stop();
      ref.read(isSharingProvider.notifier).off();
      state = const AsyncData(null);
    }
  }

  Future<void> clearHistory() async {
    await ref.read(locationRepositoryProvider).clearHistory();
    ref.invalidate(myLocationProvider);
  }
}

final locationControllerProvider =
    AsyncNotifierProvider<LocationController, void>(LocationController.new);
