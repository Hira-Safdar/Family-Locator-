import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const _minimumSplashDuration = Duration(milliseconds: 1800);

final minimumSplashProvider = FutureProvider<void>((ref) async {
  final completer = Completer<void>();
  final timer = Timer(_minimumSplashDuration, completer.complete);
  ref.onDispose(timer.cancel);
  await completer.future;
});
