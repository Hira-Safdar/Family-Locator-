import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/group_categories.dart';
import '../../core/errors/failure.dart';
import '../../core/utils/code_generator.dart';
import '../models/group_model.dart';
import '../services/firebase_auth_services.dart';
import '../services/firestore_services.dart';

class GroupRepository {
  GroupRepository(this._firestore, this._authService);

  final FirestoreServices _firestore;
  final FirebaseAuthServices _authService;

  Future<GroupModel> createGroup({
    required String name,
    String category = GroupCategories.custom,
  }) async {
    try {
      final ownerId = _authService.currentUserId;
      if (ownerId == null) {
        throw const AuthFailure('You need to be signed in to create a group.');
      }

      final template = GroupModel(
        id: '',
        name: name,
        category: category,
        inviteCode: CodeGenerator.generate(),
        ownerId: ownerId,
        memberIds: [ownerId],
        createdAt: DateTime.now(),
      );

      final base = uniqueId(name: name, category: category);
      var attempt = 0;
      while (true) {
        final candidate = attempt == 0 ? base : '${base}_$attempt';

        final reserved = await _reserve(candidate, template);
        if (reserved != null) {
          return GroupModel(
            id: reserved,
            name: template.name,
            category: template.category,
            inviteCode: template.inviteCode,
            ownerId: template.ownerId,
            memberIds: template.memberIds,
            createdAt: template.createdAt,
          );
        }

        attempt++;
        if (attempt > 50) {
          throw const FirestoreFailure(
            'That group name is taken too many times. Please pick a different name.',
          );
        }
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Failed to create group. Please check your internet connection and try again.',
      );
    }
  }

  Future<String?> _reserve(String docId, GroupModel template) {
    return _firestore.transaction<String?>((tx) async {
      final ref = _firestore.collection('groups').doc(docId);
      final snap = await tx.get(ref);
      if (snap.exists) return null;
      tx.set(ref, template.toJson()..['id'] = docId);
      return docId;
    });
  }

  String uniqueId({required String name, required String category}) {
    return '${slug(category)}_${slug(name)}';
  }

  String slug(String value) {
    final parts = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'group' : parts.join('_');
  }

  Future<bool> isNameTaken({
    required String name,
    required String category,
  }) async {
    try {
      final data = await _firestore.getDoc(
        'groups/${uniqueId(name: name, category: category)}',
      );
      return data != null;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } catch (_) {
      throw const NetworkFailure(
        'Could not check that group name. Please check your internet connection and try again.',
      );
    }
  }

  Future<List<String>> suggestNames({
    required String name,
    required String category,
    int count = 2,
  }) async {
    final suggestions = <String>[];
    var index = 0;
    while (suggestions.length < count && index < 10) {
      final candidate = index == 0 ? name : '$name $index';
      final taken = await isNameTaken(name: candidate, category: category);
      if (!taken) suggestions.add(candidate);
      index++;
    }
    return suggestions;
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
        throw const FirestoreFailure(
          'Invalid invite code. Please check the code and try again.',
        );
      }
      final doc = snap.docs.first;
      final group = GroupModel.fromJson(doc.data());
      if (group.ownerId == uid) {
        throw const GroupAlreadyMemberFailure(
          'You are the owner of this group. You are already a part of it.',
        );
      }
      if (group.containsMember(uid)) {
        throw const GroupAlreadyMemberFailure(
          'You are already a member of this group.',
        );
      }
      final newMember = <String>[...group.memberIds, uid];
      await _firestore.runTransaction((ts) async {
        final ref = _firestore.collection('groups').doc(group.id);
        ts.update(ref, {
          'memberIds': FieldValue.arrayUnion([uid]),
        });
      });
      return group.copyWith(memberIds: newMember);
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Failed to join group. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> sendSos({
    required String groupId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uid = _authService.currentUserId;
      if (uid == null) {
        throw const AuthFailure('You need to be signed in to send an SOS.');
      }
      await _firestore.updateDoc('groups/$groupId', {
        'sos': {
          'uid': uid,
          'name': _authService.currentUserName ?? 'A member',
          'latitude': latitude,
          'longitude': longitude,
          'createdAt': DateTime.now().toIso8601String(),
        },
      });
      await _firestore.collection('alerts').add({
        'groupId': groupId,
        'uid': uid,
        'name': _authService.currentUserName ?? 'A member',
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': DateTime.now().toIso8601String(),
        'resolvedAt': null,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not send SOS. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> resolveSos(String groupId) async {
    try {
      await _firestore.updateDoc('groups/$groupId', {
        'sos': FieldValue.delete(),
      });
      final snap = await _firestore
          .collection('alerts')
          .where('groupId', isEqualTo: groupId)
          .get();
      final open = snap.docs
          .where((doc) => doc.data()['resolvedAt'] == null)
          .toList();
      if (open.isNotEmpty) {
        open.sort((a, b) {
          final at = DateTime.tryParse(a.data()['createdAt'] as String? ?? '');
          final bt = DateTime.tryParse(b.data()['createdAt'] as String? ?? '');
          return (bt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            at ?? DateTime.fromMillisecondsSinceEpoch(0),
          );
        });
        await open.first.reference.update({
          'resolvedAt': DateTime.now().toIso8601String(),
        });
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not clear the alert. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> removeMember({
    required String groupId,
    required String uid,
  }) async {
    try {
      final me = _authService.currentUserId;
      if (me == null) {
        throw const AuthFailure('You need to be signed in.');
      }
      final data = await _firestore.getDoc('groups/$groupId');
      if (data == null) {
        throw const FirestoreFailure('This group no longer exists.');
      }
      if (data['ownerId'] != me) {
        throw const FirestoreFailure(
          'Only the group owner can remove members.',
        );
      }
      await _firestore.updateDoc('groups/$groupId', {
        'memberIds': FieldValue.arrayRemove([uid]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not remove member. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      final me = _authService.currentUserId;
      if (me == null) {
        throw const AuthFailure('You need to be signed in.');
      }
      await _firestore.updateDoc('groups/$groupId', {
        'memberIds': FieldValue.arrayRemove([me]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not leave the group. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      final me = _authService.currentUserId;
      if (me == null) {
        throw const AuthFailure('You need to be signed in.');
      }
      final data = await _firestore.getDoc('groups/$groupId');
      if (data == null) {
        throw const FirestoreFailure('This group no longer exists.');
      }
      if (data['ownerId'] != me) {
        throw const FirestoreFailure(
          'Only the group owner can delete this group.',
        );
      }
      await _firestore.deleteDoc('groups/$groupId');
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not delete the group. Please check your internet connection and try again.',
      );
    }
  }

  Stream<List<GroupModel>> groupsContaining(String uid) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .snapshots()
        .map(
          (q) => q.docs.map((doc) => GroupModel.fromJson(doc.data())).toList(),
        );
  }

  Stream<List<GroupModel>> getUserGroups() {
    final uid = _authService.currentUserId;
    if (uid == null) return Stream<List<GroupModel>>.value(const []);
    return groupsContaining(uid);
  }

  Stream<GroupModel> groupStream(String groupId) {
    if (groupId.isEmpty) {
      return Stream<GroupModel>.error(
        const GroupNotFoundFailure('This group no longer exists.'),
      );
    }
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
