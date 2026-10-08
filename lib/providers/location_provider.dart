import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/failure.dart';
import '../data/models/location_point.dart';
import '../data/repositories/location_repository.dart';
import '../data/services/firebase_auth_services.dart';
import '../data/services/firestore_services.dart';
import '../data/services/location_service.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';


final locationServicesProvider = Provider<LocationServices>((ref){
  return LocationServices();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref){
  return LocationRepository(
    FirestoreServices(),
    FirebaseAuthServices(),
  );
});

final myLocationProvider = StreamProvider<LocationPoint?>((ref){
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
    final services = ref.read(locationServicesProvider);
    final allowed = await services.ensurePermission();
    if(!allowed){
      state = AsyncError(
        LocationPermissionFailure('Location Permission not granted.'),
        StackTrace.current,
      );
      return;
    }
    services.stopTracking();
    final seconds = ref.read(settingsProvider).refreshSeconds;
    services.startTracking(_handlePoint, seconds: seconds);
    ref.read(isSharingProvider.notifier).on();
    state = const AsyncData(null);
  }

  Future<void> restart() async {
    if (!ref.read(isSharingProvider)) return;
    await start();
  }

  Future<void> stop() async {
    ref.read(locationServicesProvider).stopTracking();
    ref.read(isSharingProvider.notifier).off();
    state = const AsyncData(null);
  }

  void _handlePoint(LocationPoint point) {
    ref
        .read(locationRepositoryProvider)
        .saveLatest(point)
        .catchError((_) {});
  }
}

final locationControllerProvider =
AsyncNotifierProvider<LocationController, void>(LocationController.new);