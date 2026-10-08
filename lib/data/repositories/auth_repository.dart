import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/failure.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_services.dart';
import '../services/firestore_services.dart';

class AuthRepository {
  AuthRepository(this._authService, this._firestore);

  final FirebaseAuthServices _authService;
  final FirestoreServices _firestore;

  Stream<String?> authStateChanges() {
    return _authService.authStateChanges().map((user) => user?.uid);
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await _authService.signUp(email: email, password: password, name: name);
      final uid = _authService.currentUserId;
      if (uid == null) {
        throw const AuthFailure('Signup Failed. Please try again.');
      }
      try {
        await _firestore.setDoc(
          'users/$uid',
          UserProfile(uid: uid, name: name, email: email).toJson(),
        );
      } catch (_) {}
      return UserProfile(uid: uid, name: name, email: email);
    } on Failure {
      rethrow;
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (_) {
      throw const NetworkFailure(
        'Check your internet connection and try again.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.signIn(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (_) {
      throw const NetworkFailure(
        'Check your internet connection and try again.',
      );
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<void> updateProfile({String? name, String? photoFilePath}) async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      throw const AuthFailure('No signed-in account found.');
    }

    final cleanName = name?.trim();
    String? photoData;
    if (photoFilePath != null && photoFilePath.isNotEmpty) {
      final bytes = await File(photoFilePath).readAsBytes();
      photoData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    final data = <String, dynamic>{
      if (cleanName != null && cleanName.isNotEmpty) 'name': cleanName,
      'photoUrl': ?photoData,
    };
    if (data.isNotEmpty) {
      await _firestore.updateDoc('users/$uid', data);
    }
    if (cleanName != null && cleanName.isNotEmpty) {
      await _authService.updateDisplayName(cleanName);
    }
  }

  Future<void> deleteAccount() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      throw const AuthFailure('No signed-in account found.');
    }

    final groups = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .get();

    for (final doc in groups.docs) {
      final data = doc.data();
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      final ownerId = data['ownerId'] as String? ?? '';
      members.remove(uid);

      if (ownerId == uid) {
        if (members.isEmpty) {
          await _firestore.deleteDoc('groups/${doc.id}');
        } else {
          await _firestore.updateDoc('groups/${doc.id}', {
            'ownerId': members.first,
            'memberIds': members,
          });
        }
      } else {
        await _firestore.updateDoc('groups/${doc.id}', {
          'memberIds': members,
        });
      }
    }

    await _firestore.deleteDoc('location_points/$uid');
    await _firestore.deleteDoc('users/$uid');
    await _authService.deleteAccount();
  }

  Future<String?> userName(String uid) async {
    final data = await _firestore.getDoc('users/$uid');
    return data?['name'] as String?;
  }

  Future<Map<String, dynamic>?> userDoc(String uid) {
    return _firestore.getDoc('users/$uid');
  }

  AuthFailure _mapAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure('Invalid email or password. Please try again.');
      case 'user-not-found':
        return const AuthFailure(
          'No account found with this email. Please sign up.',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'This email is already in use. Please sign in or use a different email.',
        );
      case 'invalid-email':
        return const AuthFailure(
          'The email address is not valid. Please enter a valid email.',
        );
      case 'weak-password':
        return const AuthFailure(
          'The password is too weak. Please choose a stronger password.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'Too many failed attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network error. Please check your internet connection.',
        );
      case 'requires-recent-login':
        return const AuthFailure(
          'For security, please log out, sign in again, then retry.',
        );
      case 'no-current-user':
        return const AuthFailure('No signed-in account found.');
      default:
        return const AuthFailure(
          'An unknown error occurred. Please try again later.',
        );
    }
  }
}
