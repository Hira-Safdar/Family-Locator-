import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';

class PushService {
  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<void> sendSos({
    required List<String> tokens,
    required String senderName,
    required String senderUid,
    required String groupId,
    required String groupName,
  }) async {
    if (tokens.isEmpty) return;
    final serviceAccount = AppConfig.fcmServiceAccountB64;
    if (serviceAccount.isEmpty) return;
    try {
      final json =
          jsonDecode(utf8.decode(base64.decode(serviceAccount)))
              as Map<String, dynamic>;
      final credentials = ServiceAccountCredentials.fromJson(json);
      final client = await clientViaServiceAccount(credentials, [_scope]);
      try {
        for (final token in tokens) {
          await _send(
            client,
            token: token,
            title: 'SOS from $senderName',
            body: '$senderName needs help in $groupName.',
            data: {'type': 'sos', 'groupId': groupId, 'uid': senderUid},
          );
        }
      } finally {
        client.close();
      }
    } catch (_) {}
  }

  Future<void> _send(
    http.Client client, {
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    await client.post(
      Uri.parse(
        'https://fcm.googleapis.com/v1/projects/${AppConfig.fcmProjectId}/messages:send',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data': data,
          'android': {
            'priority': 'high',
            'notification': {'channel_id': 'sos_alerts'},
          },
          'apns': {
            'payload': {
              'aps': {'sound': 'default'},
            },
          },
        },
      }),
    );
  }
}
