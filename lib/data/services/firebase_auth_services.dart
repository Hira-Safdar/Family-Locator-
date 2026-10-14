import 'package:firebase_auth/firebase_auth.dart' as fb;

class FirebaseAuthServices {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _auth.currentUser?.updateProfile(displayName: name);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateProfile(displayName: name);
  }

  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final credential = fb.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;
  String? get currentUserEmail => _auth.currentUser?.email;
}
