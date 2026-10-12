import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/firebase_auth_services.dart';
import '../data/services/firestore_services.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuthServices(), FirestoreServices());
});

final authStateProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final userNameProvider = FutureProvider.family<String?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userName(uid);
});

final userDocProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userDoc(uid);
});

final userProfileProvider =
    FutureProvider.family<UserProfile?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userProfile(uid);
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(email: email, password: password, name: name);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? photoFilePath}) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(name: name, photoFilePath: photoFilePath);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
