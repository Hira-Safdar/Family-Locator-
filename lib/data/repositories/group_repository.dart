import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/failure.dart';
import '../../core/utils/code_generator.dart';
import '../models/group_model.dart';
import '../services/firebase_auth_services.dart';
import '../services/firestore_services.dart';

class GroupRepository {
  GroupRepository(this._firestore, this._authService);

  final FirestoreServices _firestore;
  final FirebaseAuthServices _authService;


  Future<GroupModel> createGroup({required String name}) async {
    try{
    final ownerId = _authService.currentUserId;
    if (ownerId == null) {
      throw const AuthFailure('You need to be signed in to create a group.');
    }
    final groupRef =_firestore.collection('groups').doc();
    final group = GroupModel(
      id: groupRef.id,
      name: name,
      inviteCode: CodeGenerator.generate(),
      ownerId: ownerId,
      memberIds: [ownerId],
      createdAt: DateTime.now()
    );
    await _firestore.setDoc('groups/${group.id}', group.toJson());
    return group;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } catch(_) {
      throw const NetworkFailure('Failed to create group. Please check your internet connection and try again.');  
    }
  }

  Future<GroupModel> joinGroup({required String inviteCode}) async {
    try {
    final uid = _authService.currentUserId;
    if (uid == null) {
      throw const AuthFailure('You need to be signed in to join a group.');
    }
    final snap = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();
        if (snap.docs.isEmpty) {
          throw const FirestoreFailure('Invalid invite code. Please check the code and try again.');
        }
        final doc = snap.docs.first;
        final group = GroupModel.fromJson(doc.data());
        if (group.containsMember(uid)) {
          throw const GroupAlreadyMemberFailure('You are already in this group.');
        }
        final newMember= <String>[...group.memberIds, uid];
        await _firestore.runTransaction((ts) async {
          final ref = _firestore.collection('groups').doc(group.id);
          ts.update(ref,{
            'memberIds': FieldValue.arrayUnion([uid]),
            });
          });
          return group.copyWith(memberIds: newMember);
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } catch (_) {
      throw const NetworkFailure('Failed to join group. Please check your internet connection and try again.');
    }
    }
    Stream<List<GroupModel>> getUserGroups() {
      final uid = _authService.currentUserId;
      return _firestore
          .collection('groups')
          .where('memberIds', arrayContains: uid)
          .snapshots()
          .map((q) => q.docs.map((doc) => GroupModel.fromJson(doc.data())).toList());
    }

    Stream<GroupModel> groupStream(String groupId) {
      return _firestore
          .docStream('groups/$groupId')
          .map((snap) => GroupModel.fromJson(snap.data() ?? {}));
    }

    String _firestoreMessage(FirebaseException e) {
      switch (e.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action.';
        case 'not-found':
          return 'The requested document was not found.';
        default:
          return 'An unexpected error occurred. Please try again.';
      }
    }
  }