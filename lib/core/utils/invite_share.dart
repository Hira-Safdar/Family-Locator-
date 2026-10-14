import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareInvite({
  required String groupName,
  required String inviteCode,
}) {
  final text =
      'Join "$groupName" on Family Locator. Use invite code: $inviteCode';
  return SharePlus.instance.share(ShareParams(text: text));
}

void copyInviteCode(BuildContext context, String inviteCode) {
  Clipboard.setData(ClipboardData(text: inviteCode));
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text('Invite code $inviteCode copied')),
    );
}
