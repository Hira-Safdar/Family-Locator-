import 'package:firebase_auth/firebase_auth.dart' as fb;

class FirebaseAuthServices{
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _auth.createUserWithEmailAndPassword(email:email,password:password);
    await _auth.currentUser?.updateProfile(displayName: name);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async{
    await _auth.signInWithEmailAndPassword(email: email,password:password);
  }

  Future<void> signOut() => _auth.signOut();
  String? get currentUserId => _auth.currentUser?.uid;
}