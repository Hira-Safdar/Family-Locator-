import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setDoc(String path, Map<String, dynamic> data){
    return _db.doc(path).set(data);
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data){
    return _db.doc(path).update(data);
  }

  Future<void> deleteDoc(String path){
    return _db.doc(path).delete();
  }
  
  Stream<DocumentSnapshot<Map<String,dynamic>>> docStream(String path){
    return _db.doc(path).snapshots();
  }

  Future<Map<String, dynamic>?> getDoc(String path) async {
    final snap = await _db.doc(path).get();
    return snap.data();
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }
  
  Future<void> runTransaction(
    Future<void> Function(Transaction tx) action,
    ) async{
      return _db.runTransaction(action);
    }

  Future<T> transaction<T>(
    Future<T> Function(Transaction tx) action,
  ) {
    return _db.runTransaction<T>(action);
  }
}