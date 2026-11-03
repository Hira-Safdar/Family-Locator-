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
      final data = template.toJson()..['id'] = docId;
      tx.set(ref, data);
      tx.set(_firestore.collection('invite_codes').doc(template.inviteCode), {
        'groupId': docId,
        'name': template.name,
        'category': template.category,
        'inviteCode': template.inviteCode,
        'ownerId': template.ownerId,
        'createdAt': template.createdAt,
      });
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
      final invite = await _firestore.getDoc('invite_codes/$inviteCode');
      if (invite == null) {
        throw const FirestoreFailure(
          'Invalid invite code. Please check the code and try again.',
        );
      }
      final groupId = invite['groupId'] as String? ?? '';
      final code = invite['inviteCode'] as String? ?? inviteCode;
      if (groupId.isEmpty) {
        throw const FirestoreFailure('This invite is no longer valid.');
      }
      final requestId = '${code}_$uid';
      await _firestore.setDoc('join_requests/$requestId', {
        'code': code,
        'groupId': groupId,
        'uid': uid,
      });
      try {
        await _firestore.updateDoc('groups/$groupId', {
          'memberIds': FieldValue.arrayUnion([uid]),
        });
      } finally {
        await _firestore.deleteDoc('join_requests/$requestId');
      }
      return GroupModel(
        id: groupId,
        name: invite['name'] as String? ?? 'Group',
        category: invite['category'] as String? ?? GroupCategories.custom,
        inviteCode: code,
        ownerId: invite['ownerId'] as String? ?? '',
        memberIds: [uid],
        createdAt:
            (invite['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
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

  Future<void> renameGroup({
    required String groupId,
    required String name,
  }) async {
    try {
      final me = _authService.currentUserId;
      if (me == null) {
        throw const AuthFailure('You need to be signed in.');
      }
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const FirestoreFailure('Group name cannot be empty.');
      }
      final data = await _firestore.getDoc('groups/$groupId');
      if (data == null) {
        throw const FirestoreFailure('This group no longer exists.');
      }
      if (data['ownerId'] != me) {
        throw const FirestoreFailure(
          'Only the group owner can rename this group.',
        );
      }
      await _firestore.updateDoc('groups/$groupId', {'name': trimmed});
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not rename the group. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> transferOwnership({
    required String groupId,
    required String newOwnerId,
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
          'Only the group owner can transfer ownership.',
        );
      }
      final members = List<String>.from(data['memberIds'] as List? ?? const []);
      if (!members.contains(newOwnerId)) {
        throw const FirestoreFailure(
          'That person is not a member of this group.',
        );
      }
      await _firestore.updateDoc('groups/$groupId', {
        'ownerId': newOwnerId,
        'memberIds': FieldValue.arrayUnion([newOwnerId]),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure(_firestoreMessage(e));
    } on Failure {
      rethrow;
    } catch (_) {
      throw const NetworkFailure(
        'Could not transfer ownership. Please check your internet connection and try again.',
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
      final inviteCode = data['inviteCode'] as String?;
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await _firestore.deleteDoc('invite_codes/$inviteCode');
      }
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
    return groupsContaining(uid).asyncMap((groups) async {
      for (final group in groups) {
        if (group.ownerId == uid) {
          await ensureInviteCode(group);
        }
      }
      return groups;
    });
  }

  Future<void> ensureInviteCode(GroupModel group) async {
    final existing = await _firestore.getDoc(
      'invite_codes/${group.inviteCode}',
    );
    if (existing != null) return;
    await _firestore.setDoc('invite_codes/${group.inviteCode}', {
      'groupId': group.id,
      'name': group.name,
      'category': group.category,
      'inviteCode': group.inviteCode,
      'ownerId': group.ownerId,
      'createdAt': group.createdAt,
    });
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
      case 'unavailable':
        return 'Firebase is temporarily unavailable. Check your internet connection and try again.';
      case 'deadline-exceeded':
        return 'The request timed out. Check your internet connection and try again.';
      case 'aborted':
        return 'The group was changed while it was being created. Please try again.';
      case 'failed-precondition':
        return 'Firebase is not ready for this operation. Please try again.';
      case 'resource-exhausted':
        return 'Firebase has temporarily reached a usage limit. Please wait a moment and try again.';
      case 'not-found':
        return 'The requested document was not found.';
      default:
        return 'Firebase error (${e.code}). Please try again.';
    }
  }
}
