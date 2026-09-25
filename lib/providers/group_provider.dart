import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/group_model.dart';
import '../data/repositories/group_repository.dart';
import '../data/services/firebase_auth_services.dart';
import '../data/services/firestore_services.dart';

final firestoreServicesProvider = Provider<FirestoreServices>((ref) {
  return FirestoreServices();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(
    FirestoreServices(),
    FirebaseAuthServices(),
  );
});

final myGroupsStreamProvider = StreamProvider<List<GroupModel>>((ref) {
  return ref.watch(groupRepositoryProvider).getUserGroups();
});

final groupStreamProvider = StreamProvider.family<GroupModel, String>((ref, groupId) {
  return ref.watch(groupRepositoryProvider).groupStream(groupId);
});

class GroupController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createGroup({required String name}) async {
    state = const AsyncLoading();
    try {
      await ref.read(groupRepositoryProvider).createGroup(name: name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> joinGroup({required String inviteCode}) async {
    state = const AsyncLoading();
    try {
      await ref.read(groupRepositoryProvider).joinGroup(inviteCode: inviteCode);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final groupControllerProvider =
    AsyncNotifierProvider<GroupController, void>(GroupController.new);