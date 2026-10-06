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
      repo.latestPoint(uid).handleError((_) {}).listen((point) {
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