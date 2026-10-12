import '../models/alert_record.dart';
import '../services/firestore_services.dart';

class AlertRepository {
  AlertRepository(this._firestore);

  final FirestoreServices _firestore;

  Stream<List<AlertRecord>> myAlerts(String uid) {
    return _firestore
        .collection('alerts')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => AlertRecord.fromJson(doc.id, doc.data()))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }
}