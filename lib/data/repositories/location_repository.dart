import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/failure.dart';
import '../models/location_point.dart';
import '../services/firebase_auth_services.dart';
import '../services/firestore_services.dart';

class LocationRepository {
  LocationRepository(this._firestore, this._authService);

  final FirestoreServices _firestore;
  final FirebaseAuthServices _authService;


  Future<void> saveLatest(LocationPoint point) async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      throw const AuthFailure('You need to be signed in to share location.');
    }
    try{
      await _firestore.setDoc('location_points/$uid', point.toJson());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } catch(_) {
      throw const NetworkFailure('Failed to save location.Please check your internet connection.');
    }
  }

  Stream<LocationPoint?> latestPoint(String uid) {
    return _firestore
          .docStream('location_points/$uid')
          .map((snap) {
            final data = snap.data();
            return data == null ? null : LocationPoint.fromJson(data);
  
  });
}

  String _firestoreMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission denied':
        return 'you dont have permission to save location.';
      default:
        return 'An unexpected error occurred.Please try again.';
    }
  }
}
