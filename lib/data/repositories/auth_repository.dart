import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/errors/failure.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_services.dart';

class AuthRepository{
  AuthRepository(this._authService);
  
  final FirebaseAuthServices _authService;

  Stream<String?> authStateChanges() {
    return _authService.authStateChanges().map((user) => user?.uid);
  }

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String name,
  }) async{
    try{
      await _authService.signUp(email:email,password:password, name:name);
      final uid = _authService.currentUserId;
      if(uid == null) {
        throw const AuthFailure('Signup Failed. Please try again.');
      }
      return UserProfile(uid:uid,name:name,email:email);
    } on fb.FirebaseAuthException catch (e){
      throw _mapAuthError(e);
    } catch (_){
      throw const NetworkFailure('Check your internet connection and try again.');
    }
  }

  Future<void> signIn({required String email, required String password}) async{
    try{
      await _authService.signIn(email:email,password:password);
    } on fb.FirebaseAuthException catch (e){
      throw _mapAuthError(e);
    } catch (_){
      throw const NetworkFailure('Check your internet connection and try again.');
    }
  }

  Future<void> signOut() => _authService.signOut();

  AuthFailure _mapAuthError(fb.FirebaseAuthException e){
    switch (e.code){
      case 'wrong-password':
        return const AuthFailure('Invalid email or password. Please try again.');
      case 'user-not-found':
        return const AuthFailure('No account found with this email. Please sign up.');
      case 'email-already-in-use':
        return const AuthFailure('This email is already in use. Please sign in or use a different email.');
      case 'invalid-email':
        return const AuthFailure('The email address is not valid. Please enter a valid email.');
      case 'weak-password':
        return const AuthFailure('The password is too weak. Please choose a stronger password.');
      default:
        return const AuthFailure('An unknown error occurred. Please try again later.');
    }
  }
}