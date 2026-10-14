import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/alert_record.dart';
import '../data/repositories/alert_repository.dart';
import '../data/services/firestore_services.dart';
import 'auth_provider.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(FirestoreServices());
});

final alertHistoryProvider = StreamProvider<List<AlertRecord>>((ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(const <AlertRecord>[]);
  return ref.watch(alertRepositoryProvider).myAlerts(uid);
});

class AlertController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> clearHistory() async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    state = const AsyncLoading();
    try {
      await ref.read(alertRepositoryProvider).clearMyAlerts(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final alertControllerProvider =
    AsyncNotifierProvider<AlertController, void>(AlertController.new);