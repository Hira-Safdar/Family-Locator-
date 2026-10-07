import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/group_model.dart';
import '../data/models/location_point.dart';
import '../data/repositories/location_repository.dart';
import 'group_provider.dart';
import 'location_provider.dart';

final memberLocationsProvider = StreamProvider<Map<String, LocationPoint>>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  final groups = ref.watch(myGroupsStreamProvider).value ?? const <GroupModel>[];
  if (groups.isEmpty) return Stream.value(const <String, LocationPoint>{});

  final selectedId = ref.watch(selectedGroupIdProvider);
  final active = groups.firstWhere(
    (g) => g.id == selectedId,
    orElse: () => groups.first,
  );

  return _combineMemberLocations(active.memberIds, repo).map(
    (map) => Map<String, LocationPoint>.fromEntries(
      map.entries
          .where((entry) => entry.value != null)
          .map((entry) => MapEntry(entry.key, entry.value!)),
    ),
  );
});

Stream<Map<String, LocationPoint?>> _combineMemberLocations(
  List<String> memberIds,
  LocationRepository repo,
) async* {
  final latest = <String, LocationPoint?>{
    for (final uid in memberIds) uid: null,
  };
  final controller = StreamController<Map<String, LocationPoint?>>();
  final subs = <StreamSubscription<LocationPoint?>>[];

  for (final uid in memberIds) {
    subs.add(
      _withRetry(() => repo.latestPoint(uid)).listen((point) {
        latest[uid] = point;
        if (!controller.isClosed) controller.add(Map.of(latest));
      }),
    );
  }

  try {
    yield* controller.stream;
  } finally {
    for (final sub in subs) {
      unawaited(sub.cancel());
    }
    unawaited(controller.close());
  }
}

Stream<LocationPoint?> _withRetry(
  Stream<LocationPoint?> Function() source,
) {
  const maxAttempts = 5;
  final controller = StreamController<LocationPoint?>();
  StreamSubscription<LocationPoint?>? sub;
  Timer? timer;

  void connect(int attempt) {
    sub = source().listen(
      controller.add,
      onError: (Object _) {
        if (controller.isClosed) return;
        if (attempt >= maxAttempts - 1) {
          controller.close();
          return;
        }
        timer = Timer(Duration(milliseconds: 500 * (1 << attempt)), () {
          if (!controller.isClosed) connect(attempt + 1);
        });
      },
      onDone: controller.close,
      cancelOnError: true,
    );
  }

  controller.onListen = () => connect(0);
  controller.onCancel = () async {
    timer?.cancel();
    await sub?.cancel();
  };
  return controller.stream;
}