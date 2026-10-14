import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/firebase_auth_services.dart';
import '../data/services/firestore_services.dart';
import '../data/services/messaging_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuthServices(), FirestoreServices());
});

final messagingServiceProvider = Provider<MessagingService>(
  (ref) => MessagingService(),
);

final authStateProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

final emailVerifiedProvider = FutureProvider<bool>((ref) async {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return true;
  return ref.watch(authRepositoryProvider).refreshEmailVerified();
});

final userNameProvider = FutureProvider.family<String?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).userName(uid);
});

final userDocProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  uid,
) {
  return ref.watch(authRepositoryProvider).userDoc(uid);
});

final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
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

  Future<void> updateProfile({
    String? name,
    String? photoFilePath,
    String? phone,
    bool removePhoto = false,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            name: name,
            photoFilePath: photoFilePath,
            phone: phone,
            removePhoto: removePhoto,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).changeEmail(
            currentPassword: currentPassword,
            newEmail: newEmail,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
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

  Future<void> sendPasswordReset(String email) {
    return ref.read(authRepositoryProvider).sendPasswordReset(email);
  }

  Future<void> resendVerification() {
    return ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<void> signOut() async {
    final uid = ref.read(authStateProvider).value;
    try {
      if (uid != null) {
        await ref.read(authRepositoryProvider).clearFcmToken(uid);
      }
      await ref.read(messagingServiceProvider).deleteToken();
    } catch (_) {}
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
