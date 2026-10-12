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