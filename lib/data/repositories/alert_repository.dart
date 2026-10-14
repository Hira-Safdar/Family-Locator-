import '../models/alert_record.dart';
import '../services/firestore_services.dart';

class AlertRepository {
  AlertRepository(this._firestore);

  final FirestoreServices _firestore;

  Future<void> clearMyAlerts(String uid) async {
    final snap = await _firestore
        .collection('alerts')
        .where('uid', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      await _firestore.deleteDoc('alerts/${doc.id}');
    }
  }

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