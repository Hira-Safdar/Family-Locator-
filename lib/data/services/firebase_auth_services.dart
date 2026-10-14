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

  Future<void> verifyBeforeUpdateEmail(String email) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(email.trim());
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  Future<bool> refreshEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return true;
    try {
      await user.reload();
    } catch (_) {}
    return _auth.currentUser?.emailVerified ?? true;
  }

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName;
  String? get currentUserEmail => _auth.currentUser?.email;
}
