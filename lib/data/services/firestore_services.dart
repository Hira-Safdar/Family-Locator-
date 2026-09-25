import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices{
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> setDoc(String path, Map<String, dynamic> data){
    return _db.doc(path).set(data);
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data){
    return _db.doc(path).update(data);
  }
  
  Stream<DocumentSnapshot<Map<String,dynamic>>> docStream(String path){
    return _db.doc(path).snapshots();
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }
  
  Future<void> runTransaction(
    Future<void> Function(Transaction tx) action,
    ) async{
      return _db.runTransaction(action);
    }
}